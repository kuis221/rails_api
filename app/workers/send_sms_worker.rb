class SendSmsWorker
  include Sidekiq::Worker
  sidekiq_options queue: :notification, retry: 3

  def perform(phone_number, message)
    return unless phone_number.present? &&
       (TO_PHONE_NUMBERS_ALLOWED == '*' || TO_PHONE_NUMBERS_ALLOWED.include?(phone_number))
    client = Twilio::REST::Client.new(TWILIO_SID, TWILIO_AUTH_TOKEN)
    client.account.sms.messages.create(
        to: phone_number,
        from: TWILIO_PHONE_NUMBER,
        body: message)
  end
end
