require 'rails_helper'

RSpec.describe InactiveUrnListApiSyncJob do
  describe '#perform' do
    let(:rows) do
      [
        {
          'InactiveURN' => '10009655',
          'InactiveCustomerName' => 'Government Commercial Agency',
          'DateMadeInactive' => '2024-01-01',
          'ReplacementURN' => '10009656',
          'ReplacementName' => 'Another Organisation',
          'ReplacementPostCode' => 'AB1 2CD',
          'ReplacementStatus' => 'active'
        }
      ]
    end

    let(:api_client_service) do
      double('UrnLists::ApiClient', fetch_inactive_rows: rows)
    end

    let(:import_inactive_customers_service) do
      double('UrnLists::ImportInactiveCustomers', call: rows.count)
    end

    before do
      allow(UrnLists::ApiClient).to receive(:new).and_return(api_client_service)
      allow(UrnLists::ImportInactiveCustomers).to receive(:new).with(rows: rows).and_return(import_inactive_customers_service)
    end

    it 'creates a pending inactive customer import, imports the rows, and marks it as processed' do
      expect do
        described_class.perform_now
      end.to change(InactiveCustomerImport, :count).by(1)

      expect(api_client_service).to have_received(:fetch_inactive_rows)
      expect(import_inactive_customers_service).to have_received(:call)

      inactive_customer_import = InactiveCustomerImport.last

      expect(inactive_customer_import.aasm_state).to eq('processed')
      expect(inactive_customer_import.records_count).to eq(rows.count)
      expect(inactive_customer_import.completed_at).not_to be_nil
    end

    it 'handles errors during the import process and marks the import as failed' do
      allow(api_client_service).to receive(:fetch_inactive_rows).and_raise(StandardError.new('API error'))

      expect do
        described_class.perform_now
      end.to raise_error(StandardError, 'API error')

      inactive_customer_import = InactiveCustomerImport.last

      expect(inactive_customer_import.aasm_state).to eq('failed')
      expect(inactive_customer_import.records_count).to eq(0)
      expect(inactive_customer_import.completed_at).not_to be_nil
    end

    it 'marks the import as failed when the import fails after rows are fetched' do
      allow(import_inactive_customers_service).to receive(:call).and_raise(StandardError.new('Import error'))

      expect do
        described_class.perform_now
      end.to raise_error(StandardError, 'Import error')

      inactive_customer_import = InactiveCustomerImport.last

      expect(inactive_customer_import.aasm_state).to eq('failed')
      expect(inactive_customer_import.records_count).to eq(0)
      expect(inactive_customer_import.completed_at).not_to be_nil
    end
  end
end
