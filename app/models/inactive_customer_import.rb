class InactiveCustomerImport < ApplicationRecord
  include AASM

  aasm do
    state :pending, initial: true
    state :processed
    state :failed
  end
end
