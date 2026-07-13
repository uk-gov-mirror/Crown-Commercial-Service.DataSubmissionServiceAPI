require 'rails_helper'

RSpec.feature 'Admin can search for URNs' do
  before do
    @customer1 = FactoryBot.create(:customer, urn: '123', name: 'Customer One', postcode: 'AB1 2CD',
sector: :central_government)
    @customer2 = FactoryBot.create(:customer, urn: '456', name: 'Customer Two', postcode: 'EF3 4GH',
sector: :wider_public_sector)
    @customer3 = FactoryBot.create(:customer, urn: '789', name: 'Customer Three', postcode: 'IJ5 6KL',
sector: :wider_public_sector)
    sign_in_as_admin
  end

  scenario 'Viewing all URNs' do
    visit admin_urns_path
    expect(page).to have_content '123'
    expect(page).to have_content '456'
    expect(page).to have_content '789'
  end

  scenario 'Searching by customer name' do
    visit admin_urns_path
    fill_in 'Search', with: 'One'
    click_button 'Search'
    expect(page).to have_content '123'
    expect(page).to_not have_content '456'
    expect(page).to_not have_content '789'
  end

  scenario 'Searching by URN' do
    visit admin_urns_path
    fill_in 'Search', with: '456'
    click_button 'Search'
    expect(page).to_not have_content '123'
    expect(page).to have_content '456'
    expect(page).to_not have_content '789'
  end

  scenario 'Searching by postcode' do
    visit admin_urns_path
    fill_in 'Search', with: 'IJ5 6KL'
    click_button 'Search'
    expect(page).to_not have_content '123'
    expect(page).to_not have_content '456'
    expect(page).to have_content '789'
  end
end
