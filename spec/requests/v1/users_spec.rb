require 'rails_helper'

RSpec.describe '/v1' do
  describe 'GET /v1/users/?filter[auth_id]=' do
    it 'returns the details of the current user' do
      user = FactoryBot.create(:user)

      get '/v1/users', headers: { 'X-Auth-Id' => JWT.encode(user.auth_id, 'test') }

      expect(response).to be_successful
      expect(json['data'].size).to eql 1
      expect(json['data'][0]).to have_id(user.id)
      expect(json['data'][0])
        .to have_attribute(:name)
        .with_value('User Name')
      expect(json['data'][0])
        .to have_attribute(:multiple_suppliers?)
        .with_value(false)
    end

    it 'returns the details of the current user who belongs to more than one supplier' do
      user = FactoryBot.create(:user)
      user.suppliers << FactoryBot.create_list(:supplier, 2)

      get '/v1/users', headers: { 'X-Auth-Id' => JWT.encode(user.auth_id, 'test') }

      expect(json['data'].size).to eql 1
      expect(response).to be_successful
      expect(json['data'][0])
        .to have_attribute(:multiple_suppliers?)
        .with_value(true)
    end
  end

  describe 'PATCH /v1/users/update_name' do
    it 'updates the name of the current user' do
      user = FactoryBot.create(:user)
      stub_auth0_token_request
      stub_auth0_update_user_request(user)

      patch '/v1/users/update_name',
            headers: { 'X-Auth-Id' => JWT.encode(user.auth_id, 'test') },
            params: {
              _jsonapi: {
                name: 'New User Name'
              }
            }

      expect(response).to be_successful
      expect(json['data']).to have_id(user.id)
      expect(json['data'])
        .to have_attribute(:name)
        .with_value('New User Name')
    end

    it 'returns an error if the Auth0 update fails' do
      user = FactoryBot.create(:user)
      stub_auth0_token_request
      stub_auth0_update_user_request_failure(user)

      patch '/v1/users/update_name',
            headers: { 'X-Auth-Id' => JWT.encode(user.auth_id, 'test') },
            params: {
              _jsonapi: {
                name: 'New User Name'
              }
            }

      expect(response.status).to eq 422
    end
  end

  describe 'PATCH /v1/users/update_email' do
    it 'returns 422 if email param is missing' do
      user = FactoryBot.create(:user)
      stub_auth0_token_request
      stub_auth0_update_user_request(user)
      patch '/v1/users/update_email',
            headers: { 'X-Auth-Id' => JWT.encode(user.auth_id, 'test') },
            params: { _jsonapi: {} }
      expect(response.status).to eq 422
      expect(json['errors']).not_to be_empty
    end

    it 'returns 422 if verification_request fails to save' do
      user = FactoryBot.create(:user)
      allow_any_instance_of(EmailChangeRequest).to receive(:save).and_return(false)
      patch '/v1/users/update_email',
            headers: { 'X-Auth-Id' => JWT.encode(user.auth_id, 'test') },
            params: { _jsonapi: { email: 'newuser@example.com' } }
      expect(response.status).to eq 422
      expect(json['errors']).not_to be_empty
    end
    it 'updates the email of the current user' do
      user = FactoryBot.create(:user)
      stub_auth0_token_request
      stub_auth0_update_user_request(user)

      patch '/v1/users/update_email',
            headers: { 'X-Auth-Id' => JWT.encode(user.auth_id, 'test') },
            params: {
              _jsonapi: {
                email: 'newuser@example.com'
              }
            }

      expect(response).to be_successful
      expect(json['data']['type']).to eq('email_change_requests')
      expect(json['data']['attributes']['new_email']).to eq('newuser@example.com')
    end

    it 'returns an error if the Auth0 update fails' do
      user = FactoryBot.create(:user)
      stub_auth0_token_request
      stub_auth0_update_user_request_failure(user)

      patch '/v1/users/update_email',
            headers: { 'X-Auth-Id' => JWT.encode(user.auth_id, 'test') },
            params: {
              _jsonapi: {
                email: 'newuser@example.com'
              }
            }

      expect(response.status).to eq 200
    end
  end
end
