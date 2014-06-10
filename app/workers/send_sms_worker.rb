class SendSmsWorker
  include Resque::Plugins::UniqueJob
  @queue = :sms

  def self.perform(phone_number, message)
    begin
      p phone_number
      p message
      Rails.logger.info phone_number
      Rails.logger.info message
      #Verify phone numbers white list to send the message
      if phone_number.present? &&
         (TO_PHONE_NUMBERS_ALLOWED == '*' || TO_PHONE_NUMBERS_ALLOWED.include?(phone_number))
        client = Twilio::REST::Client.new TWILIO_SID, TWILIO_AUTH_TOKEN
        p TWILIO_SID
        p TWILIO_AUTH_TOKEN
        p client
        Rails.logger.info TWILIO_SID
        Rails.logger.info TWILIO_AUTH_TOKEN
        Rails.logger.info client.inspect
        message = client.account.sms.messages.create(
                    :to => phone_number,
                    :from => TWILIO_PHONE_NUMBER,
                    :body => message
                  )
        #Rails.logger.info "MESSAGE SID: #{message.sid} MESSAGE STATUS: #{message.status}"
      end
    rescue Twilio::REST::RequestError => e
      puts e.message
    end
  end
end