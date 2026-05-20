class V2::SubmissionsController < ActionController::API
  include ApiKeyAuthenticatable

  def index
    @submissions = Submission.all
    if params[:updated_at].present?
      @submissions = @submissions.where(updated_at: Time.zone.parse(params[:updated_at])..Time.zone.now)
    end

    render json: @submissions
  rescue ArgumentError
    render json: { error: 'updated_at must be a valid date or datetime' }, status: :bad_request
  end
end
