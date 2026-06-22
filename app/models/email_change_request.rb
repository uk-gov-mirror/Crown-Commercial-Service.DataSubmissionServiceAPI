class EmailChangeRequest < ApplicationRecord
  has_secure_token :token, length: 64
  belongs_to :user

  validates :new_email, presence: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :expires_at, presence: true
  validate :new_email_not_taken
  validate :email_not_verified
  validate :verifiable, on: :update

  def self.verified_email(user, new_email)
    where(user: user, new_email: new_email, active: false)
      .where.not(used_at: nil)
      .order(used_at: :desc)
      .first
  end

  def email_not_verified
    return if self.class.verified_email(user, new_email).blank?

    errors.add(:new_email, I18n.t('email_verifications.already_verified'))
  end

  def verification_url
    "#{ENV['FRONTEND_URL']}/email/verification/#{token}"
  end

  def verifiable
    used_at.nil? && expires_at > Time.current
  end

  private

  def new_email_not_taken
    return unless User.exists?(email: new_email)

    errors.add(:new_email, 'is already taken')
  end
end
