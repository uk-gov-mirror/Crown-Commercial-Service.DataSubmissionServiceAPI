require 'rails_helper'

RSpec.describe UrnListApiSyncJob do
  describe '#perform' do
    let(:rows) do
      [
        Customer.new(
          urn: 10009655,
          name: 'Government Commercial Agency',
          postcode: 'L3 9PP',
          sector: 'central_government',
          deleted: false,
          published: true
        ),
        Customer.new(
          urn: 10009656,
          name: 'Another Organisation',
          postcode: 'AB1 2CD',
          sector: 'wider_public_sector',
          deleted: false,
          published: true
        )
      ]
    end

    let(:api_client_service) { double('UrnLists::ApiClient', fetch_rows: rows) }
    let(:import_customers_service) { double('UrnLists::ImportCustomers', call: rows.count) }

    before do
      allow(UrnLists::ApiClient).to receive(:new).and_return(api_client_service)
      allow(UrnLists::ImportCustomers).to receive(:new).with(rows: rows).and_return(import_customers_service)
    end

    it 'creates a pending urn list, imports the rows, and marks it as processed' do
      expect do
        described_class.perform_now
      end.to change(UrnList, :count).by(1)

      expect(api_client_service).to have_received(:fetch_rows)
      expect(import_customers_service).to have_received(:call)

      urn_list = UrnList.last
      expect(urn_list.source).to eq('api_import')
      expect(urn_list).to be_processed
      expect(urn_list.processed_count).to eq(rows.count)
      expect(urn_list.completed_at).to be_present
    end

    it 'marks the urn list as failed when the api call fails' do
      allow(api_client_service).to receive(:fetch_rows).and_raise(StandardError.new('token failed'))

      expect do
        described_class.perform_now
      end.to raise_error(StandardError, 'token failed')

      urn_list = UrnList.last
      expect(urn_list.source).to eq('api_import')
      expect(urn_list).to be_failed
      expect(urn_list.processed_count).to eq(0)
      expect(urn_list.completed_at).to be_present
    end

    it 'marks the urn list as failed when the import fails after rows are fetched' do
      allow(import_customers_service).to receive(:call).and_raise(StandardError.new('import failed'))

      expect do
        described_class.perform_now
      end.to raise_error(StandardError, 'import failed')

      urn_list = UrnList.last
      expect(urn_list.source).to eq('api_import')
      expect(urn_list).to be_failed
      expect(urn_list.processed_count).to eq(0)
      expect(urn_list.completed_at).to be_present
    end
  end
end
