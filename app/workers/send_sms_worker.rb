class SendSmsWorker
  include Resque::Plugins::UniqueJob
  @queue = :sms

  def self.perform(phone_number, message)
    begin
      #Verify phone numbers white list to send the message
      if phone_number.present? &&
         (TO_PHONE_NUMBERS_ALLOWED == '*' || TO_PHONE_NUMBERS_ALLOWED.include?(phone_number))
        client = Twilio::REST::Client.new TWILIO_SID, TWILIO_AUTH_TOKEN
        message = client.account.sms.messages.create(
                    :to => phone_number,
                    :from => TWILIO_PHONE_NUMBER,
                    :body => message
                  )
      end
    rescue Twilio::REST::RequestError => e
      puts e.message
    end
  end
end