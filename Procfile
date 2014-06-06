redis-server: redis-server

web: env USE_SUNSPOT_QUEUE=1 bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: env LOG_CONSOLE=1 TERM_CHILD=1 INTERVAL=0.5   bundle exec resque-pool -c config/resque_pool/all.yml
big_jobs: env TERM_CHILD=1 INTERVAL=0.5   bundle exec resque-pool -c config/resque_pool/big.yml
small_jobs: env TERM_CHILD=1 INTERVAL=0.5   bundle exec resque-pool -c config/resque_pool/small.yml
migration_jobs: env TERM_CHILD=1  bundle exec resque-pool -c config/resque_pool/migration.yml


search-solr: bundle exec rake sunspot:solr:run
