require 'rails_helper'

RSpec.describe UrnLists::ImportInactiveCustomers do
  describe '#call' do
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

    it 'imports inactive customers into the database' do
      expect do
        described_class.new(rows: rows).call
      end.to change(InactiveCustomer, :count).by(1)

      inactive_customer = InactiveCustomer.last
      expect(inactive_customer.inactive_urn).to eq(10009655)
      expect(inactive_customer.inactive_customer_name).to eq('Government Commercial Agency')
      expect(inactive_customer.date_made_inactive).to eq(Date.iso8601('2024-01-01'))
      expect(inactive_customer.replacement_urn).to eq('10009656')
      expect(inactive_customer.replacement_customer_name).to eq('Another Organisation')
      expect(inactive_customer.replacement_post_code).to eq('AB1 2CD')
      expect(inactive_customer.replacement_status).to eq('active')
    end

    it 'does not create duplicate records for the same inactive urn' do
      InactiveCustomer.create!(
        inactive_urn: '10009655',
        inactive_customer_name: 'Government Commercial Agency',
        date_made_inactive: Date.iso8601('2024-01-01'),
        replacement_urn: '10009656',
        replacement_customer_name: 'Another Organisation',
        replacement_post_code: 'AB1 2CD',
        replacement_status: 'active'
      )

      expect do
        described_class.new(rows: rows).call
      end.not_to change(InactiveCustomer, :count)
    end
  end
end
