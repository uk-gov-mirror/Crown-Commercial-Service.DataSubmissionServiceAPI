class InactiveUrnListApiSyncJob < ApplicationJob
  def perform
    inactive_customer_import = InactiveCustomerImport.create!(aasm_state: :pending)

    rows = UrnLists::ApiClient.new.fetch_inactive_rows
    count = UrnLists::ImportInactiveCustomers.new(rows: rows).call

    inactive_customer_import.update!(
        aasm_state: :processed,
        records_count: count, 
        completed_at: Time.current
      )
  rescue StandardError => e
    inactive_customer_import&.update!(
      aasm_state: :failed,
      completed_at: Time.current,
      records_count: count || 0
      )

  raise e
  end
end
