if Rails.env.production?
  require 'rake'
  require 'airbrake/rake_handler'
  Airbrake.configure do |config|
    config.api_key = 'ab711b3a909036274cbd1ea24809ec9f'
    config.host        = 'errors.jaskotmedia.com'
    config.port        = 80
    config.secure      = config.port == 443
    config.development_environments = []
    config.environment_name = ENV['HEROKU_APP_NAME'] || Rails.env
    config.rescue_rake_exceptions = true

    config.ignore << 'SignalException'

    config.user_attributes = [:id, :name, :email]

    config.async do |notice|
      AirbrakeDeliveryWorker.perform_async(notice.to_xml)
    end
  end
end
