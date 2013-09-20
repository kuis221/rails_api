redis: redis-server
web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: env TERM_CHILD=1 bundle exec rake resque:work
small_jobs: env TERM_CHILD=1 QUEUE="sunspot,indexing" bundle exec rake resque:work
big_jobs: env TERM_CHILD=1 QUEUE="download,upload,export" bundle exec rake resque:work
migration_jobs: env TERM_CHILD=1 QUEUE="migration" bundle exec rake resque:work
search: bundle exec rake sunspot:solr:run