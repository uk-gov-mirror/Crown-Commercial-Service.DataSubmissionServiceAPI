require 'rails_helper'

RSpec.describe Notification, type: :model do
  describe 'validations' do
    subject { create(:notification, published: true) }
    it { is_expected.to validate_presence_of(:summary) }
    it { is_expected.to validate_presence_of(:notification_message) }

    it 'is invalid if stop_datetime is in the past' do
      notification = build(:notification, stop_datetime: 1.day.ago)
      expect(notification).not_to be_valid
      expect(notification.errors[:stop_datetime]).to include('must be in the future')
    end

    it 'is valid if stop_datetime is in the future' do
      notification = build(:notification, stop_datetime: 1.day.from_now)
      expect(notification).to be_valid
    end

    it 'is valid if stop_datetime is nil' do
      notification = build(:notification, stop_datetime: nil)
      expect(notification).to be_valid
    end
  end

  describe 'scopes' do
    describe '.currently_active' do
      it 'includes published notifications with future stop dates' do
        active = create(:notification, published: true, stop_datetime: 1.hour.from_now)
        expect(Notification.currently_active).to include(active)
      end

      it 'includes published notifications with no stop date' do
        permanent = create(:notification, published: true, stop_datetime: nil)
        expect(Notification.currently_active).to include(permanent)
      end

      it 'excludes notifications that have passed their stop date' do
        # Use save(validate: false) to simulate an old record that was valid when created
        expired = build(:notification, published: true, stop_datetime: 1.hour.ago)
        expired.save(validate: false)
        expect(Notification.currently_active).not_to include(expired)
      end
    end
  end

  describe '.expire_past_due!' do
    it 'updates all past-due notifications to be unpublished' do
      expired = build(:notification, published: true, stop_datetime: 1.minute.ago)
      expired.save(validate: false)

      Notification.expire_past_due!

      expired.reload
      expect(expired.published).to be false
      expect(expired.unpublished_at).to be_within(1.second).of(Time.zone.now)
    end
  end

  describe '#unpublish!' do
    let!(:notification) do
      create :notification, published: true, notification_message: 'It may be too late for another coffee'
    end
    subject! { notification.unpublish! }
    it 'sets published value to false and the unpublished_at timestamp' do
      notification.reload
      expect(notification.published).to be_falsey
      expect(notification.unpublished_at).not_to be_nil
    end
  end

  describe 'publishing logic' do
    it 'unpublishes other notifications when a new one is published' do
      first_notification = create(:notification, published: true)
      create(:notification, published: true, notification_message: 'Beware the dog')

      first_notification.reload
      expect(first_notification.published).to be_falsey
    end
  end
end
