class SendConfirmEmailVerificationJob < ApplicationJob
  queue_as :default

  TEMPLATE_ID = '59cda9d1-9a70-4196-8b50-fba71e410765'.freeze

  def perform(new_email:, person_name: nil)
    Notify.new.send_email(
      template_id: TEMPLATE_ID,
      email: new_email,
      vars: {
        login_url: ENV['FRONTEND_URL'],
        email_address: new_email,
        person_name: person_name
      }
    )
  end
end
