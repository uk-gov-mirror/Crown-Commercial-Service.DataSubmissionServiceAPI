class UrnListApiSyncJob < ApplicationJob
  def perform
    urn_list = UrnList.create!(aasm_state: :pending, source: 'api_import')

    rows = UrnLists::ApiClient.new.fetch_rows
    count = UrnLists::ImportCustomers.new(rows: rows).call

    urn_list.update!(
      aasm_state: :processed,
      completed_at: Time.current,
      processed_count: count
    )
  rescue StandardError => e
    urn_list.update!(
      aasm_state: :failed,
      completed_at: Time.current,
      processed_count: count || 0
    )
    raise e
  end
end
