if Rails.env.production?
  Airbrake.configure do |config|
    config.api_key = '4c06476135f92dd6dd572613f9a68434'
    config.host        = 'errors.jaskotmedia.com'
    config.port        = 80
    config.secure      = config.port == 443
    config.development_environments = ['development', 'test']
  end
elsif Rails.env.staging?
  Airbrake.configure do |config|
    config.api_key = 'ab711b3a909036274cbd1ea24809ec9f'
    config.host        = 'errors.jaskotmedia.com'
    config.port        = 80
    config.secure      = config.port == 443
    config.development_environments = ['development', 'test']
  end
end