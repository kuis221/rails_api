TWILIO_SID = ENV['TWILIO_SID']
TWILIO_AUTH_TOKEN = ENV['TWILIO_AUTH_TOKEN']
TWILIO_PHONE_NUMBER = ENV['TWILIO_PHONE_NUMBER']
TO_PHONE_NUMBERS_ALLOWED = ENV['TO_PHONE_NUMBERS_ALLOWED'].present? ? ENV['TO_PHONE_NUMBERS_ALLOWED'] : '*'
