FactoryBot.define do
  factory :notification do
    summary { 'Hello there' }
    notification_message { 'Wear sunscreen' }
    published { false }
    published_at { Time.zone.now }
    stop_datetime { nil }
    unpublished_at { nil }
    user { 'testy.mctestface@example.com' }
  end
end
