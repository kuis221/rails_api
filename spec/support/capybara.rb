
Capybara.register_driver :poltergeist_debug do |app|
  Capybara::Poltergeist::Driver.new(app, inspector: true, debug: true)
end

# Capybara.javascript_driver = :webkit
# Capybara.javascript_driver = :selenium
Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = 5

# Capybara.server_port = 7000
# Capybara.app_host = "http://localhost:#{Capybara.server_port}"
# ActionController::Base.asset_host = Capybara.app_host
RSpec.configure do |config|
  config.before(:each) do |example|
    if example.metadata[:js]
      Rails.application.routes.default_url_options[:host] = Capybara.current_session.server.host
      Rails.application.routes.default_url_options[:port] = Capybara.current_session.server.port
    else
      Rails.application.routes.default_url_options[:host] = 'localhost'
      Rails.application.routes.default_url_options[:port] = 5100
    end
  end
end
