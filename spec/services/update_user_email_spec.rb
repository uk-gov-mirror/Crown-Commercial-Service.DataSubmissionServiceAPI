require 'rails_helper'

RSpec.describe UpdateUserEmail do
  let(:user) { FactoryBot.create(:user) }

  before(:each) do
    stub_auth0_token_request
  end

  describe '#call' do
    it 'returns true on success' do
      stub_auth0_update_user_request(user)

      result = described_class.new(user, 'newemail@example.com').call

      expect(result).to eq(true)
    end

    it 'updates the user email' do
      stub_auth0_update_user_request(user)

      described_class.new(user, 'newemail@example.com').call

      expect(user.reload.email).to eq('newemail@example.com')
    end

    it 'enqueues a confirmation email job' do
      stub_auth0_update_user_request(user)

      expect do
        described_class.new(user, 'newemail@example.com').call
      end.to have_enqueued_job(SendConfirmEmailVerificationJob).with(new_email: 'newemail@example.com',
                                                                     person_name: user.name)
    end

    context 'when Auth0 errors' do
      before(:each) do
        stub_auth0_update_user_request_failure(user)
      end

      it 'returns false' do
        result = described_class.new(user, 'newemail@example.com').call
        expect(result).to eq(false)
      end

      it 'does not update the user email' do
        original_email = user.email
        described_class.new(user, 'newemail@example.com').call
        expect(user.reload.email).to eq(original_email)
      end

      it 'logs a failure message' do
        expect(Rails.logger).to receive(:error).with(/Auth0 Error/)
        described_class.new(user, 'newemail@example.com').call
      end
    end
  end
end
