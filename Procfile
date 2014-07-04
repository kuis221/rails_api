redis-server: redis-server

web: env WEB=1 bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: env LOG_CONSOLE=1 TERM_CHILD=1 INTERVAL=0.5   bundle exec resque-pool -c config/resque_pool/all.yml
big_jobs: env LOG_CONSOLE=1 TERM_CHILD=1 INTERVAL=0.5   bundle exec resque-pool -c config/resque_pool/big.yml
uploads: env LOG_CONSOLE=1 TERM_CHILD=1 INTERVAL=0.5   bundle exec resque-pool -c config/resque_pool/upload.yml
exports: env LOG_CONSOLE=1 TERM_CHILD=1 INTERVAL=0.5   bundle exec resque-pool -c config/resque_pool/export.yml
small_jobs: env LOG_CONSOLE=1 TERM_CHILD=1 INTERVAL=0.5   bundle exec resque-pool -c config/resque_pool/small.yml
migration_jobs: env LOG_CONSOLE=1 TERM_CHILD=1  bundle exec resque-pool -c config/resque_pool/migration.yml

guard-livereload: bundle exec guard
search-solr: bundle exec rake sunspot:solr:run
