require 'csv'

class Admin::UrnsController < AdminController
  def index
    @search = params[:search].to_s.strip

    @customers = Customer.where(deleted: false).order(:name).search(@search).page(params[:page])
  end

  def download
    send_data urn_csv,
              type: 'text/csv',
              disposition: 'attachment',
              filename: "customer_urns_#{Time.zone.today}.csv"
  end

  private

  def urn_csv
    CSV.generate(headers: true) do |csv|
      csv << ['URN', 'CustomerName', 'PostCode', 'Sector', 'Published']

      Customer.where(deleted: false).order(:name).find_each do |customer|
        csv << [customer.urn, customer.name, customer.postcode, customer.sector, customer.published]
      end
    end
  end
end
