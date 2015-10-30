Sidekiq.configure_client do |config|
  if ENV['REDISTOGO_URL']
    config.redis = { url: ENV['REDISTOGO_URL'], namespace: "your-app" }
  elsif Rails.env.development?
    config.redis = { url: 'redis://127.0.0.1:6379' }
  end
end
