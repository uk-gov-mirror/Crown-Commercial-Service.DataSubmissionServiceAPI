require 'rails_helper'

RSpec.describe Admin::UsersController, type: :request do
  let(:admin) { FactoryBot.create(:user) }
  let(:user) { FactoryBot.create(:user) }

  before do
    allow_any_instance_of(AdminController).to receive(:ensure_user_signed_in).and_return(true)
    allow_any_instance_of(AdminController).to receive(:current_user).and_return({ 'email' => admin.email })
    stub_auth0_token_request
    stub_auth0_update_user_request(user)
  end

  describe 'GET /admin/users/:id/edit_email' do
    it 'renders the edit email form' do
      get edit_email_admin_user_path(user)
      expect(response).to have_http_status(:ok)
      expect(response.body).to include('Update user email')
    end
  end

  describe 'PATCH /admin/users/:id/update_email' do
    it 'updates the user email if changed' do
      patch update_email_admin_user_path(user),
            params: { user: { email: 'newadmin@example.com' } }
      expect(response).to redirect_to(admin_user_path(user))
      follow_redirect!
      expect(response.body).to include('Email updated successfully')
    end

    it 'does not update if email is unchanged' do
      patch update_email_admin_user_path(user),
            params: { user: { email: user.email } }
      expect(response).to redirect_to(admin_user_path(user))
      follow_redirect!
      expect(response.body).to include('Email is unchanged')
    end
  end
end
