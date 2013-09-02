unless Rails.env.development? || Rails.env.test?
  Airbrake.configure do |config|
    config.api_key     = 'fb0bbd895c45136607e9cecb23bcaa9d'
    config.host        = 'jaskotmedia-errbit.herokuapp.com'
    config.port        = 80
    config.secure      = config.port == 443
  end
end