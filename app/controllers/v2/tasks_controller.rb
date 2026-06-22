class V2::TasksController < ActionController::API
  include ApiKeyAuthenticatable

  def index
    @tasks = Task.all
    if params[:updated_at].present?
      @tasks = @tasks.where(updated_at: Time.zone.parse(params[:updated_at])..Time.zone.now)
    end

    render json: @tasks
  rescue ArgumentError
    render json: { error: 'updated_at must be a valid date or datetime' }, status: :bad_request
  end
end
