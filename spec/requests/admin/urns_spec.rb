require 'rails_helper'
require 'csv'

RSpec.describe 'Admin URNs', type: :request do
  include SingleSignOnHelpers

  before do
    stub_govuk_bank_holidays_request
    mock_sso_with(email: 'admin@example.com')
    get '/auth/google_oauth2/callback'
  end

  describe 'GET /admin/urns' do
    it 'renders the URN search page' do
      get admin_urns_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Active URN list')
      expect(response.body).to include('Search')
      expect(response.body).to include('Download Active URN list')
    end
  end

  describe 'GET /admin/urns/download' do
    let!(:active_customer) do
      create(:customer, urn: '123', name: 'Active Customer One', postcode: 'AB1 2CD', sector: :central_government)
    end
    let!(:deleted_customer) do
      create(:customer, urn: '456', name: 'Deleted Customer', postcode: 'IJ5 6KL', sector: :wider_public_sector,
     deleted: true)
    end

    it 'returns a CSV file with active customers' do
      get download_admin_urns_path

      expect(response).to have_http_status(:ok)
      expect(response.headers['Content-Type']).to include('text/csv')
      expect(response.headers['Content-Disposition']).to include("filename=\"customer_urns_#{Time.zone.today}.csv\"")

      csv = CSV.parse(response.body, headers: true)
      expect(csv.headers).to eq(['URN', 'CustomerName', 'PostCode', 'Sector', 'Published'])
      expect(csv.length).to eq(1)

      expect(csv[0]['URN']).to include('123')
      expect(csv[0]['CustomerName']).to eq(active_customer.name)
      expect(csv[0]['PostCode']).to eq(active_customer.postcode)
      expect(csv[0]['Sector']).to eq(active_customer.sector)

      # Ensure deleted customer is not included
      csv.each do |row|
        expect(row['URN']).not_to include('456')
        expect(row['CustomerName']).not_to eq(deleted_customer.name)
        expect(row['PostCode']).not_to eq(deleted_customer.postcode)
      end
    end
  end
end
