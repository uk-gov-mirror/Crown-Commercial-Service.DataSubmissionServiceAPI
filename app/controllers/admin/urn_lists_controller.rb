class Admin::UrnListsController < AdminController
  before_action :find_latest_list, only: %i[index]

  def index
    @urn_lists = UrnList.order(created_at: :desc).page(params[:page])
  end

  def new
    @urn_list = UrnList.new
  end

  def create
    @urn_list = UrnList.new(urn_list_params.merge(source: 'manual_upload'))

    if @urn_list.save
      UrnListImporterJob.perform_later(@urn_list)

      redirect_to admin_urn_lists_path
    end
  rescue ActionController::ParameterMissing
    redirect_to new_admin_urn_list_path, alert: 'Please choose a file to upload'
  end

  private

  def urn_list_params
    params.require(:urn_list).permit(:excel_file)
  end

  def find_latest_list
    @latest_urn_list = UrnList.where(source: 'manual_upload', aasm_state: 'processed').order(created_at: :desc).first
  end

  def s3_client
    @s3_client ||= Aws::S3::Client.new(region: ENV['AWS_S3_REGION'])
  end

  def bucket
    ENV.fetch('AWS_S3_BUCKET')
  end
end
