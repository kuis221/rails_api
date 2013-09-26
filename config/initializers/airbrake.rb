if Rails.env.production? or Rails.env.staging?
  require 'resque/failure/redis'
  require 'resque/failure/multiple'
  require 'resque/failure/airbrake'
  Resque::Failure::Multiple.classes = [Resque::Failure::Redis, Resque::Failure::Airbrake]
  Resque::Failure.backend = Resque::Failure::Multiple

  Airbrake.configure do |config|
    config.api_key = 'ab711b3a909036274cbd1ea24809ec9f'
    config.host        = 'errors.jaskotmedia.com'
    config.port        = 80
    config.secure      = config.port == 443
    config.development_environments = ['development', 'test']
  end
end