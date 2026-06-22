module UrnLists
  class ImportCustomers
    def initialize(rows:)
      @rows = rows
    end

    def call
      customers = build_customers
      soft_delete!(customers)
      upsert!(customers)

      customers.count
    end

    private

    attr_reader :rows

    def build_customers
      rows.map do |row|
        next row if row.is_a?(Customer)

        Customer.new(
          name: row['CustomerName'],
          urn: row['URN'].to_i,
          postcode: row['PostCode'],
          sector: normalize_sector(row['Sector']),
          deleted: false,
          published: normalize_published(row['Published'])
        )
      end
    end

    def normalize_sector(value)
      value == 'Central Government' ? :central_government : :wider_public_sector
    end

    def normalize_published(value)
      return true if value.nil?

      value != 'False'
    end

    def upsert!(customers)
      Customer.transaction do
        Customer.import(
          customers,
          batch_size: 100,
          on_duplicate_key_update: {
            conflict_target: [:urn],
            columns: %i[name postcode sector deleted published]
          }
        )
      end
    end

    def soft_delete!(customers)
      existing_urns = Customer.pluck(:urn)
      importing_urns = customers.map(&:urn)

      urns_to_be_deleted = existing_urns - importing_urns

      Customer.where(urn: urns_to_be_deleted).update(deleted: true)
    end
  end
end
