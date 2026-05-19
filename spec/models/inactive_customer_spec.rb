require 'rails_helper'

RSpec.describe InactiveCustomer do
  subject { FactoryBot.create(:inactive_customer) }

  it { is_expected.to validate_presence_of(:inactive_urn) }
  it { is_expected.to validate_uniqueness_of(:inactive_urn) }
end
