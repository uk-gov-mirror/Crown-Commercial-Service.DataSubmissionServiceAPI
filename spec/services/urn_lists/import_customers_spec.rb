require 'rails_helper'

RSpec.describe UrnLists::ImportCustomers do
  describe '#call' do
    context 'when given customer objects' do
      let(:rows) do
        [
          Customer.new(
            urn: 10009655,
            name: 'Government Commercial Agency',
            postcode: 'L3 9PP',
            sector: 'central_government',
            deleted: false,
            published: true
          )
        ]
      end

      it 'upserts the customers' do
        expect do
          described_class.new(rows: rows).call
        end.to change(Customer, :count).by(1)
      end
    end

    context 'when given raw data rows' do
      let(:rows) do
        [
          {
            'URN' => '10009655',
            'CustomerName' => 'Government Commercial Agency',
            'PostCode' => 'L3 9PP',
            'Sector' => 'Central Government',
            'Published' => 'True'
          }
        ]
      end

      it 'builds and upserts the customers' do
        expect do
          described_class.new(rows: rows).call
        end.to change(Customer, :count).by(1)

        customer = Customer.last

        expect(customer.urn).to eq(10009655)
        expect(customer.name).to eq('Government Commercial Agency')
        expect(customer.postcode).to eq('L3 9PP')
        expect(customer.sector).to eq('central_government')
        expect(customer.deleted).to eq(false)
        expect(customer.published).to eq(true)
      end

      it 'updates an existing customer' do
        existing_customer = create(:customer, urn: 10009655, name: 'Old Name', deleted: true)

        expect do
          described_class.new(rows: rows).call
        end.not_to change(Customer, :count)

        existing_customer.reload

        expect(existing_customer.name).to eq('Government Commercial Agency')
        expect(existing_customer.deleted).to eq(false)
      end

      it 'soft deletes customers not in the new list' do
        obsolete = create(:customer, urn: 10009656, name: 'Obsolete Customer', deleted: false)

        rows = [
          {
            'URN' => '10009655',
              'CustomerName' => 'Government Commercial Agency',
              'PostCode' => 'L3 9PP',
              'Sector' => 'Central Government',
              'Published' => 'True'
          }
        ]

        described_class.new(rows: rows).call

        expect(obsolete.reload.deleted).to eq(true)
      end

      it 'restores a previously deleted customer if it reappears in the list' do
        deleted_customer = create(:customer, urn: 10009655, name: 'Government Commercial Agency', deleted: true)

        expect do
          described_class.new(rows: rows).call
        end.not_to change(Customer, :count)

        deleted_customer.reload

        expect(deleted_customer.deleted).to eq(false)
      end
    end
  end
end
