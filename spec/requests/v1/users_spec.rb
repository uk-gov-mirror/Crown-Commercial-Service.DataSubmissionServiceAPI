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
      expect(json['data'][0])
        .to have_attribute(:can_deactivate?)
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

    it 'returns that the user can be deactivated if they are not the only active user for a supplier' do
      user = FactoryBot.create(:user)
      supplier = FactoryBot.create(:supplier)
      user.suppliers << supplier
      other_user = FactoryBot.create(:user)
      other_user.suppliers << supplier

      get '/v1/users', headers: { 'X-Auth-Id' => JWT.encode(user.auth_id, 'test') }

      expect(json['data'].size).to eql 1
      expect(response).to be_successful
      expect(json['data'][0])
        .to have_attribute(:can_deactivate?)
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

  describe 'PATCH /v1/users/deactivate' do
    let(:user) { FactoryBot.create(:user) }
    let(:headers) { { 'X-Auth-Id' => JWT.encode(user.auth_id, 'test') } }

    context 'when the user can be deactivated' do
      before do
        supplier = FactoryBot.create(:supplier)
        user.suppliers << supplier
        other_user = FactoryBot.create(:user)
        other_user.suppliers << supplier
      end

      it 'deactivates the user' do
        stub_auth0_token_request
        stub_auth0_delete_user_request(user)

        patch '/v1/users/deactivate', headers: headers

        expect(response).to be_successful
        expect(user.reload.auth_id).to be_nil
      end
    end

    context 'when the user cannot be deactivated' do
      before do
        supplier = FactoryBot.create(:supplier)
        user.suppliers << supplier
      end

      it 'returns an error' do
        patch '/v1/users/deactivate', headers: headers

        expect(response.status).to eq 422
        expect(json['errors']).not_to be_empty
        expect(user.reload.auth_id).not_to be_nil
      end
    end
  end
end
