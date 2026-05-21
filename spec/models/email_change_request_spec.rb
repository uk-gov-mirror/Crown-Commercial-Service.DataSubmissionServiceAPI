require 'rails_helper'

RSpec.describe EmailChangeRequest, type: :model do
  let(:user) { FactoryBot.create(:user) }

  describe 'validations' do
    it 'is valid with valid attributes' do
      request = FactoryBot.build(:email_change_request, user: user)
      expect(request).to be_valid
    end

    it 'is invalid without a new_email' do
      request = FactoryBot.build(:email_change_request, user: user, new_email: nil)
      expect(request).not_to be_valid
      expect(request.errors[:new_email]).to include("can't be blank")
    end

    it 'is invalid with a badly formatted email' do
      request = FactoryBot.build(:email_change_request, user: user, new_email: 'not-an-email')
      expect(request).not_to be_valid
      expect(request.errors[:new_email]).to be_present
    end

    it 'is invalid without expires_at' do
      request = FactoryBot.build(:email_change_request, user: user, expires_at: nil)
      expect(request).not_to be_valid
      expect(request.errors[:expires_at]).to include("can't be blank")
    end

    it 'is invalid if new_email is already taken by another user' do
      existing_user = FactoryBot.create(:user, email: 'taken@example.com')
      request = FactoryBot.build(:email_change_request, user: user, new_email: existing_user.email)
      expect(request).not_to be_valid
      expect(request.errors[:new_email]).to include('is already taken')
    end

    it 'is invalid if the email has already been verified for this user' do
      FactoryBot.create(:email_change_request, user: user, new_email: 'verified@example.com', active: false,
used_at: Time.current)
      request = FactoryBot.build(:email_change_request, user: user, new_email: 'verified@example.com')
      expect(request).not_to be_valid
      expect(request.errors[:new_email]).to include(I18n.t('email_verifications.already_verified'))
    end
  end

  describe '.verified_email' do
    it 'returns the most recently used verified request' do
      older = FactoryBot.build(:email_change_request, user: user, new_email: 'v@example.com', active: false,
used_at: 2.days.ago)
      older.save(validate: false)
      newer = FactoryBot.build(:email_change_request, user: user, new_email: 'v@example.com', active: false,
used_at: 1.day.ago)
      newer.save(validate: false)
      result = described_class.verified_email(user, 'v@example.com')
      expect(result).to eq(newer)
    end

    it 'returns nil when no verified request exists' do
      expect(described_class.verified_email(user, 'none@example.com')).to be_nil
    end
  end

  describe '#verification_url' do
    it 'builds the URL from FRONTEND_URL and token' do
      request = FactoryBot.create(:email_change_request, user: user)
      ClimateControl.modify FRONTEND_URL: 'https://frontend.example.com' do
        expect(request.verification_url).to eq("https://frontend.example.com/email/verification/#{request.token}")
      end
    end
  end

  describe '#verifiable' do
    it 'returns true when unused and not expired' do
      request = FactoryBot.build(:email_change_request, user: user, used_at: nil, expires_at: 2.days.from_now)
      expect(request.verifiable).to be true
    end

    it 'returns false when already used' do
      request = FactoryBot.build(:email_change_request, user: user, used_at: Time.current, expires_at: 2.days.from_now)
      expect(request.verifiable).to be false
    end

    it 'returns false when expired' do
      request = FactoryBot.build(:email_change_request, user: user, used_at: nil, expires_at: 1.day.ago)
      expect(request.verifiable).to be false
    end
  end
end
