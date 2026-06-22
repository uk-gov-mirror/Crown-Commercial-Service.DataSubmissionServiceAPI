class V1::UsersController < ApiController
  def index
    users = User.where(auth_id: current_auth_id)

    render jsonapi: users
  end

  def update_name
    user = User.find_by!(auth_id: current_auth_id)
    name_param = params.dig('_jsonapi', 'name')
    result = UpdateUser.new(user, name_param).call

    if result.success?
      render jsonapi: user, status: :ok
    else
      render jsonapi_errors: { error: I18n.t('errors.messages.error_updating_user_in_auth0') },
             status: :unprocessable_entity
    end
  end

  def update_email
    user = User.find_by(auth_id: current_auth_id)
    new_email = params.dig('_jsonapi', 'email')

    if new_email.blank?
      render jsonapi_errors: { email: ['is required'] }, status: :unprocessable_entity
      return
    end

    verification_request = verification_request(user, new_email)

    if verification_request.save
      notify_result = SendEmailVerificationJob.perform_later(
        new_email: new_email,
        verification_url: verification_request.verification_url,
        person_name: user.name
      )

      if notify_result == false
        render jsonapi_errors: { notify: ['Failed to send email'] }, status: :unprocessable_entity
        return
      end

      render jsonapi: verification_request, status: :ok, context: { request: request }
    else
      render jsonapi_errors: verification_request.errors.presence || { base: ['Failed to save verification request'] },
             status: :unprocessable_entity
    end
  end

  def verification_request(user, new_email)
    token = SecureRandom.hex(24)
    expires_at = 2.days.from_now

    EmailChangeRequest.where(user: user, active: true).find_each do |record|
      record.update(active: false)
    end

    EmailChangeRequest.new(
      user: user,
      new_email: new_email,
      token: token,
      expires_at: expires_at
    )
  end

  def user_auth_logs
    user = User.find_by!(auth_id: current_auth_id)
    auth_logs = UserLogsInAuth0.new(user: user).call
    objects = auth_logs.map do |log|
      OpenStruct.new(log.merge('id' => SecureRandom.uuid))
    end

    render jsonapi: objects, class: { OpenStruct: SerializableUserAuthLog }, status: :ok
  end
end
