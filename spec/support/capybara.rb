# Capybara.javascript_driver = :webkit
#Capybara.javascript_driver = :selenium
Capybara.javascript_driver = :poltergeist
Capybara.default_wait_time = 5
Capybara.server_port = 7000
Capybara.app_host = "http://localhost:#{Capybara.server_port}"
ActionController::Base.asset_host = Capybara.app_host
