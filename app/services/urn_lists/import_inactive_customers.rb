module UrnLists
  class ImportInactiveCustomers
    BATCH_SIZE = 1000

    def initialize(rows:)
      @rows = rows
    end

    # rubocop:disable Rails/SkipsModelValidations
    def call
      formatted_rows.each_slice(BATCH_SIZE) do |batch|
        InactiveCustomer.insert_all(
          batch,
          unique_by: :index_inactive_customers_on_inactive_urn
        )
      end
    end
    # rubocop:enable Rails/SkipsModelValidations

    private

    attr_reader :rows

    def formatted_rows
      now = Time.current

      rows.map do |row|
        {
          inactive_urn: row['InactiveURN'],
          inactive_customer_name: row['InactiveCustomerName'],
          date_made_inactive: row['DateMadeInactive'] ? Date.iso8601(row['DateMadeInactive']) : nil,
          replacement_urn: row['ReplacementURN'],
          replacement_customer_name: row['ReplacementName'],
          replacement_post_code: row['ReplacementPostCode'],
          replacement_status: row['ReplacementStatus'],
          created_at: now,
          updated_at: now
        }
      end
    end
  end
end
