require 'rails_helper'

RSpec.describe UrnLists::ReadExcel do
  describe '#call' do
    subject(:rows) { described_class.new(file_path: path).call }

    context 'with a valid workbook' do
      let(:path) { Rails.root.join('spec', 'fixtures', 'customers_test.xlsx') }
      it 'returns customer data' do
        expect(rows.size).to eq(3)
        expect(rows.first).to be_a(Customer)
      end

      it 'maps fields correctly' do
        expect(rows.first.urn).to eq(10009655)
        expect(rows.first.name).to eq('Crown Commercial Service')
        expect(rows.first.postcode).to eq('L3 9PP')
      end
    end

    context 'with missing columns' do
      let(:path) { Rails.root.join('spec', 'fixtures', 'customers_missing_columns.xlsx') }

      it 'raises invalid format' do
        expect { rows }.to raise_error(UrnLists::ReadExcel::InvalidFormat)
      end
    end
  end
end
