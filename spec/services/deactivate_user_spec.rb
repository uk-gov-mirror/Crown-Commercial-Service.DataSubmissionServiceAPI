require 'rails_helper'

RSpec.describe DeactivateUser do
  let(:suppler) { create(:supplier) }
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before(:each) do
    user.suppliers << suppler
    other_user.suppliers << suppler
    stub_auth0_token_request
  end

  describe '#call' do
    it 'returns a successful result' do
      stub_auth0_delete_user_request(user)

      result = described_class.new(user: user).call

      expect(result.success?).to eq(true)
      expect(result.failure?).to eq(false)
    end

    context 'when the user is the only active user for a supplier' do
      let(:other_user) { create(:user, :inactive) }

      it 'returns a failed result' do
        result = described_class.new(user: user).call
        expect(result).to be_failure
      end

      it 'does not delete the user in Auth0' do
        expect_any_instance_of(DeleteUserInAuth0).not_to receive(:call)
        described_class.new(user: user).call
      end

      it 'does not clear the auth_id of the user' do
        original_auth_id = user.auth_id
        described_class.new(user: user).call
        expect(user.auth_id).to eql(original_auth_id)
      end
    end

    context 'when Auth0 errors' do
      before(:each) do
        stub_auth0_delete_user_request_failure(user)
      end

      it 'returns a failed result' do
        result = described_class.new(user: user).call
        expect(result.failure?).to eq(true)
      end

      it 'does not update the user' do
        original_auth_id = user.auth_id
        described_class.new(user: user).call
        expect(user.auth_id).to eql(original_auth_id)
      end

      it 'logs a failure message' do
        expect(Rails.logger).to receive(:error)
          .with("Error adding user #{user.email} to Auth0 during DeactivateUser")
        described_class.new(user: user).call
      end
    end
  end
end
