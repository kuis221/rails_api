if ENV["RAILS_ENV"] == "development"
  worker_processes 1
else
  worker_processes Integer(ENV["WEB_CONCURRENCY"] || 3)
end

timeout 25
preload_app true

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  if defined?(Resque)
    Resque.redis.quit
    Rails.logger.info("Disconnected from Redis")
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to send QUIT'
  end

  if defined?(Resque)
    Resque.redis = REDIS
    Rails.logger.info("Connected to Redis")
  end

  defined?(ActiveRecord::Base) and
    ActiveRecord::Base.establish_connection
end
