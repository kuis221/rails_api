# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Brandscopic::Application.initialize!

if Rails.env.development? && ENV['TEST_MAIL'] == '1'
  ActionMailer::Base.delivery_method = :smtp
  ActionMailer::Base.raise_delivery_errors = true
  ActionMailer::Base.perform_deliveries = true
end