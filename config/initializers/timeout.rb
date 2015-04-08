if Rails.env.test?
  Rack::Timeout.timeout = 0  # disabled in test to avoid capybara intermittent timeouts
else
  Rack::Timeout.timeout = 25  # seconds
end
