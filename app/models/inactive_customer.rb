class InactiveCustomer < ApplicationRecord
  validates :inactive_urn, presence: true, uniqueness: true

  def self.search(query)
    if query.blank?
      all
    else
      where(
        'cast(inactive_urn as text) ILIKE :query 
        OR inactive_customer_name ILIKE :query
        OR cast(replacement_urn as text) ILIKE :query
        OR replacement_customer_name ILIKE :query
        OR replacement_post_code ILIKE :query',
        query: "%#{query}%"
      )
    end
  end
end
