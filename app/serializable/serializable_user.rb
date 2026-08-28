class SerializableUser < JSONAPI::Serializable::Resource
  type 'users'
  attributes :multiple_suppliers?, :can_deactivate?, :name, :email, :created_at
end
