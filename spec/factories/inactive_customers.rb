FactoryBot.define do
  factory :inactive_customer do
    sequence(:inactive_urn) { |n| 10009655 + n }
    inactive_customer_name { 'Department for Silly Hats' }
    date_made_inactive { Date.iso8601('2024-01-01') }

    replacement_urn { |n| 10009656 + n }
    replacement_customer_name { 'Department for Even Sillier Hats' }
    replacement_post_code { 'AB1 2CD' }
    replacement_status { 'active' }
  end
end