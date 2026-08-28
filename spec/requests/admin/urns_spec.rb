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
    let!(:active_customer) do
      create(:customer, urn: '123', name: 'Active Customer One', postcode: 'AB1 2CD', sector: :central_government)
    end

    let!(:inactive_customer) do
      create(:inactive_customer, inactive_urn: '456', inactive_customer_name: 'Inactive Customer ltd',
replacement_urn: '789', replacement_customer_name: 'Replacement Customer', replacement_post_code: 'EF4 5GH')
    end

    it 'renders the active and inactive URN tabs' do
      get admin_urns_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Active URNs')
      expect(response.body).to include('Inactive URNs')
      expect(response.body).to include('Download Active URN list')
    end

    it 'shows active customers' do
      get admin_urns_path

      expect(response.body).to include(active_customer.name)
      expect(response.body).to include(active_customer.urn.to_s)
      expect(response.body).to include(active_customer.postcode)
    end

    it 'shows inactive customers' do
      get admin_urns_path

      expect(response.body).to include(inactive_customer.inactive_customer_name)
      expect(response.body).to include(inactive_customer.inactive_urn.to_s)
      expect(response.body).to include(inactive_customer.replacement_customer_name)
      expect(response.body).to include(inactive_customer.replacement_urn.to_s)
    end

    it 'filters active customers independently' do
      other_active_customer = create(:customer, urn: '999', name: 'Other Active Customer', postcode: 'XY1 2ZQ')

      get admin_urns_path, params: { active_search: 'Other Active Customer' }

      expect(response.body).to include(other_active_customer.name)
      expect(response.body).not_to include(active_customer.name)
      expect(response.body).to include(inactive_customer.inactive_customer_name)
    end

    it 'filters inactive customers independently' do
      other_inactive_customer = create(:inactive_customer, inactive_urn: '888',
inactive_customer_name: 'Other Inactive Customer', replacement_urn: '777',
replacement_customer_name: 'Other Replacement Customer', replacement_post_code: 'GH1 2IJ')

      get admin_urns_path, params: { inactive_search: 'Other Inactive Customer' }

      expect(response.body).to include(other_inactive_customer.inactive_customer_name)
      expect(response.body).not_to include(inactive_customer.inactive_customer_name)
      expect(response.body).to include(active_customer.name)
    end

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
