require 'rails_helper'

RSpec.describe InactiveCustomer do
  subject { FactoryBot.create(:inactive_customer) }

  it { is_expected.to validate_presence_of(:inactive_urn) }
  it { is_expected.to validate_uniqueness_of(:inactive_urn) }

  describe '.search' do
    let!(:inactive_customer1) do
      FactoryBot.create(:inactive_customer, inactive_urn: 123, inactive_customer_name: 'Customer One',
     replacement_urn: 456, replacement_customer_name: 'Replacement One', replacement_post_code: 'AB12 3CD')
    end
    let!(:inactive_customer2) do
      FactoryBot.create(:inactive_customer, inactive_urn: 789, inactive_customer_name: 'Customer Two',
      replacement_urn: 101, replacement_customer_name: 'Replacement Two', replacement_post_code: 'EF45 6GH')
    end

    context 'when query is blank' do
      it 'returns all inactive customers' do
        expect(InactiveCustomer.search('')).to match_array([inactive_customer1, inactive_customer2])
      end
    end

    context 'when query matches inactive_urn' do
      it 'returns the matching inactive customer' do
        expect(InactiveCustomer.search('123')).to match_array([inactive_customer1])
      end
    end

    context 'when query matches inactive_customer_name' do
      it 'returns the matching inactive customer' do
        expect(InactiveCustomer.search('Customer Two')).to match_array([inactive_customer2])
      end
    end

    context 'when query matches replacement_urn' do
      it 'returns the matching inactive customer' do
        expect(InactiveCustomer.search('456')).to match_array([inactive_customer1])
      end
    end

    context 'when query matches replacement_customer_name' do
      it 'returns the matching inactive customer' do
        expect(InactiveCustomer.search('Replacement Two')).to match_array([inactive_customer2])
      end
    end

    context 'when query matches replacement_post_code' do
      it 'returns the matching inactive customer' do
        expect(InactiveCustomer.search('AB12 3CD')).to match_array([inactive_customer1])
      end
    end

    context 'when query does not match any attributes' do
      it 'returns an empty result set' do
        expect(InactiveCustomer.search('Nonexistent')).to be_empty
      end
    end
  end
end
