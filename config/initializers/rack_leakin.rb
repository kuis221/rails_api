Rails.application.config.middleware.use Rack::Leakin
Rack::Leakin.threshold = 20480 # 20MB

# Send notifications to airbrak/errbit
Rack::Leakin.handler = lambda do |env, beginning, ending|
  Airbrake.notify \
    :error_message => "Memory leak detected, from #{beginning}KB to #{ending}KB",
    :error_class   => 'MemoryLeak',
    :parameters => {
      :request_uri => env['REQUEST_URI'],
      :method => env['REQUEST_METHOD']
    }
end