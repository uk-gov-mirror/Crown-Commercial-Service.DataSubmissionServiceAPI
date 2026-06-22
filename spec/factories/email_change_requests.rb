FactoryBot.define do
  factory :email_change_request do
    association :user
    new_email { 'testuser@example.com' }
    token { SecureRandom.hex(24) }
    expires_at { 2.days.from_now }
    active { true }
    used_at { nil }
  end
end
