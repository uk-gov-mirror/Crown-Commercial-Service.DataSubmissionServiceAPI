class SerializableEmailChangeRequest < JSONAPI::Serializable::Resource
  type 'email_change_requests'
  attributes :new_email, :expires_at, :token, :verification_url
end
