class Notification < ApplicationRecord
  validates :summary, :notification_message, presence: true
  validate :stop_datetime_in_future

  before_save :ensure_single_published_notification

  scope :published, -> { where(published: true) }
  scope :currently_active, lambda {
    where(published: true)
      .where('stop_datetime IS NULL OR stop_datetime > ?', Time.current)
  }

  def unpublish!
    self.published = false
    self.unpublished_at = Time.zone.now
    save!
  end

  def self.expire_past_due!
    expired = where('stop_datetime < ? AND published = ?', Time.current, true)
    # We use update_all for performance to expire records in a single
    # SQL query, bypassing validations for speed on every API request.
    # rubocop:disable Rails/SkipsModelValidations
    expired.update_all(published: false, unpublished_at: Time.zone.now)
    # rubocop:enable Rails/SkipsModelValidations
  end

  private

  def ensure_single_published_notification
    return unless published_changed? && published?

    Notification.where.not(id: id).where(published: true).find_each(&:unpublish!)
  end

  def stop_datetime_in_future
    return unless stop_datetime.present? && stop_datetime < Time.current

    errors.add(:stop_datetime, 'must be in the future')
  end
end
