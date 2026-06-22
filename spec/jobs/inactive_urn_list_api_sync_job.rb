require 'rails_helper'

RSpec.describe InactiveUrnListApiSyncJob do
  describe '#perform' do
    let(:client) { instance_double(UrnLists::ApiClient) }

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

    before do
      allow(UrnLists::ApiClient).to receive(:new).and_return(client)
      allow(client).to receive(:fetch_inactive_customers).and_return(rows)
    end

    it 'fetches inactive customers and imports them into the database' do
      expect do
        described_class.perform_now
      end.to change(InactiveCustomer, :count).by(1)
    end
  end
end
