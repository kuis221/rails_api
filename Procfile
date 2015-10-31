web: env WEB=1 bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: env LOG_CONSOLE=1 bundle exec sidekiq
clock: bundle exec clockwork clock.rb