class InactiveUrnListApiSyncJob < ApplicationJob
  def perform
    rows = UrnLists::ApiClient.new.fetch_inactive_rows

    UrnLists::ImportInactiveCustomers.new(rows: rows).call
  end
end
