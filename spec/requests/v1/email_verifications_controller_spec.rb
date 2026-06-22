require 'rails_helper'

RSpec.describe V1::EmailVerificationsController, type: :request do
  let(:user) { FactoryBot.create(:user) }
  let(:auth_headers) { { 'X-Auth-Id' => JWT.encode(user.auth_id, 'test') } }

  describe 'POST /v1/email_verifications' do
    it 'creates a new email verification request' do
      post '/v1/email_verifications',
           headers: auth_headers,
           params: { _jsonapi: { new_email: 'newuser@example.com' } }

      expect(response).to have_http_status(:ok)
      expect(json['data']['type']).to eq('email_change_requests')
      expect(json['data']['attributes']['new_email']).to eq('newuser@example.com')
    end

    it 'returns errors if already verified' do
      FactoryBot.create(:email_change_request, user: user, new_email: 'newuser@example.com', active: false,
used_at: Time.current)
      post '/v1/email_verifications',
           headers: auth_headers,
           params: { _jsonapi: { new_email: 'newuser@example.com' } }
      expect(response.status).to eq(422)
      expect(json['errors']).not_to be_empty
    end
  end

  describe 'POST /v1/email_verifications/verify_token' do
    it 'verifies a valid token and updates the user email' do
      email_change = FactoryBot.create(:email_change_request, user: user, new_email: 'verified@example.com',
active: true, used_at: nil, expires_at: 2.days.from_now)
      allow_any_instance_of(UpdateUserEmail).to receive(:call).and_return(true)
      post '/v1/email_verifications/verify_token',
           params: { _jsonapi: { token: email_change.token } }
      expect(response).to have_http_status(:ok)
    end

    it 'returns error for invalid or expired token' do
      post '/v1/email_verifications/verify_token',
           params: { _jsonapi: { token: 'invalidtoken' } }
      expect(response.status).to eq(422)
      expect(json['errors']).not_to be_empty
    end
  end

  describe 'GET /v1/email_verifications/active_verification' do
    it 'returns the active email change request' do
      FactoryBot.create(:email_change_request, user: user, new_email: 'pending@example.com',
active: true, expires_at: 2.days.from_now)
      get '/v1/email_verifications/active_verification', headers: auth_headers
      expect(response).to have_http_status(:ok)
      expect(json['data']['attributes']['new_email']).to eq('pending@example.com')
    end

    it 'returns not found if no active request' do
      get '/v1/email_verifications/active_verification', headers: auth_headers
      expect(response.status).to eq(404)
    end
  end

  describe 'DELETE /v1/email_verifications/cancel_pending_email_change' do
    it 'cancels the pending email change' do
      FactoryBot.create(:email_change_request, user: user, new_email: 'cancelme@example.com', active: true,
expires_at: 2.days.from_now)
      delete '/v1/email_verifications/cancel_pending_email_change', headers: auth_headers
      expect(response).to have_http_status(:no_content)
    end
  end
end
