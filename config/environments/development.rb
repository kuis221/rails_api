$stdout.sync = true
Brandscopic::Application.configure do
  # Settings specified here will take precedence over those in config/application.rb

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports and disable caching
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations
  config.active_record.migration_error = :page_load

  # Expands the lines which load the assets
  config.assets.debug = true

  Rails.application.routes.default_url_options[:host] = "localhost"
  Rails.application.routes.default_url_options[:port] = 5100

  config.action_mailer.default_url_options = {:host => "localhost:5100"}
  config.action_controller.asset_host = "http://localhost:5100"

  #Paperclip options
  Paperclip.options[:command_path] = "/usr/local/bin"

  config.cache_store = :dalli_store

  # We want to see the logs on the console for the workers :)
  if ENV['LOG_CONSOLE']
    config.logger = Logger.new(STDOUT)
    config.logger.level = Logger.const_get(
      ENV['LOG_LEVEL'] ? ENV['LOG_LEVEL'].upcase : 'DEBUG'
    )
  end


  ENV["REDISTOGO_URL"] = 'redis://localhost:6379'

  config.middleware.insert_before(::Rack::Lock, ::Rack::LiveReload, :min_delay => 500) if defined?(Rack::LiveReload)
end
