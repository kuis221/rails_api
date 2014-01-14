redis-server: redis-server
web: bundle exec unicorn -p $PORT -c ./config/unicorn.rb
worker: env TERM_CHILD=1 INTERVAL=0.1 QUEUE="*" bundle exec rake resque:work
small_jobs: env TERM_CHILD=1 INTERVAL=0.1 QUEUE="sunspot,indexing" bundle exec rake resque:work
big_jobs: env TERM_CHILD=1 INTERVAL=0.5  QUEUE="download,upload,export" bundle exec rake resque:work
migration_jobs: env QUEUE="migration" INTERVAL=0.5 bundle exec rake resque:work
search-solr: bundle exec rake sunspot:solr:run