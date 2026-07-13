module V1
  class EmailVerificationsController < ApiController
    skip_before_action :reject_without_user!, only: [:verification]

    def create
      user = User.find_by(auth_id: current_auth_id)
      new_email = params.dig('_jsonapi', 'new_email')

      verification_request = verification_request(user, new_email)

      if verification_request.save

        SendEmailVerificationJob.perform_later(
          new_email: new_email,
          verification_url: verification_request.verification_url,
          person_name: user.name
        )

        render jsonapi: verification_request, status: :ok, context: { request: request }
      else
        render jsonapi_errors: verification_request.errors, status: :unprocessable_entity
      end
    end

    def verification
      token = find_token_params || (return render_invalid_token_error)
      email_change_request = EmailChangeRequest.find_by(token: token) || (return render_invalid_token_error)
      update_user_email = update_email(email_change_request)
      email_change_request.update(used_at: Time.current, active: false)

      return render jsonapi: email_change_request.user, status: :ok if update_user_email&.call

      error_body = verification_request&.errors ||
                   { error: I18n.t('email_verifications.invalid_or_expired_token') }
      render jsonapi_errors: error_body, status: :unprocessable_entity
    end

    def active
      user = User.find_by(auth_id: current_auth_id)
      unless user
        render jsonapi_errors: { error: 'User not found' }, status: :not_found
        return
      end

      verification = EmailChangeRequest.where(user: user, active: true).order(created_at: :desc).first

      if verification
        render jsonapi: verification, status: :ok, context: { request: request }
      else
        render jsonapi_errors: { error: 'No active email verification found' }, status: :not_found
      end
    end

    def cancel_pending_email_change
      user = User.find_by(auth_id: current_auth_id)
      unless user
        render jsonapi_errors: { error: 'User not found' }, status: :not_found
        return
      end

      EmailChangeRequest.where(user: user, active: true).find_each do |record|
        record.update(active: false)
      end

      head :no_content
    end

    private

    def verification_request(user, new_email)
      expires_at = 2.days.from_now

      EmailChangeRequest.where(user: user, active: true).find_each do |record|
        record.update(active: false)
      end

      EmailChangeRequest.new(
        user: user,
        new_email: new_email,
        expires_at: expires_at
      )
    end

    def update_email(email_change_request)
      UpdateUserEmail.new(email_change_request.user, email_change_request.new_email)
    end

    def render_invalid_token_error
      render jsonapi_errors: ApiMessage.new({ message: I18n.t('email_verifications.invalid_or_expired_token') }),
             status: :unprocessable_entity
    end

    def find_token_params
      params.dig('_jsonapi', 'token')
    end
  end
end
