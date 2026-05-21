class SerializableApiMessage < JSONAPI::Serializable::Resource
  type 'users'

  id { @object.id }

  attribute :attributes do
    @object.as_json.except(:id)
  end
end
