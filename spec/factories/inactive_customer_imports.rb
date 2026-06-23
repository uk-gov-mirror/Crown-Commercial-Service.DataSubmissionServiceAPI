FactoryBot.define do
  factory :inactive_customer_import do
    aasm_state { :pending }
    records_count { 0 }
    completed_at { nil }

    trait :processed do
      aasm_state { :processed }
      records_count { 100 }
      completed_at { Time.current }
    end

    trait :failed do
      aasm_state { :failed }
      records_count { 0 }
      completed_at { Time.current }
    end
  end
end
