web: env WEB=1 bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: bundle exec sidekiq
clock: bundle exec clockwork clock.rb