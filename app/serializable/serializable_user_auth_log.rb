# app/serializable/serializable_user_auth_log.rb
class SerializableUserAuthLog < JSONAPI::Serializable::Resource
  type 'user_auth_logs'

  attributes :date, :type, :description, :connection, :connection_id, :client_id, :client_name,
             :ip, :client_ip, :user_agent, :details, :hostname, :user_id, :user_name,
             :auth0_client, :strategy, :strategy_type, :environment_name, :log_id, :tenant_name,
             :_id, :isMobile, :location_info

  attribute :event_schema do
    @object['$event_schema']
  end
end
