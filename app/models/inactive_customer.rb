class InactiveCustomer < ApplicationRecord
  validates :inactive_urn, presence: true, uniqueness: true
end