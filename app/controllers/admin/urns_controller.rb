require 'csv'

class Admin::UrnsController < AdminController
  # rubocop:disable Metrics/AbcSize
  def index
    @active_search = params[:active_search].to_s.strip
    @inactive_search = params[:inactive_search].to_s.strip

    @customers = Customer
                 .where(deleted: false)
                 .search(@active_search)
                 .order(:name)
                 .page(params[:active_page])
    @inactive_customers = InactiveCustomer
                          .search(@inactive_search)
                          .order(date_made_inactive: :desc)
                          .page(params[:inactive_page])

    respond_to do |format|
      format.html
      format.js
    end
  end
  # rubocop:enable Metrics/AbcSize

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
