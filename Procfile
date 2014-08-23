web: env WEB=1 bundle exec unicorn -p $PORT -c ./config/unicorn.rb
big_jobs: env LOG_CONSOLE=1 TERM_CHILD=1 INTERVAL=0.5   QUEUE="export,download,upload" bundle exec rake resque:work
uploads: env LOG_CONSOLE=1 TERM_CHILD=1 INTERVAL=0.5   QUEUE="upload" bundle exec rake resque:work
exports: env LOG_CONSOLE=1 TERM_CHILD=1 INTERVAL=0.5   QUEUE="export" bundle exec rake resque:work
downloads: env LOG_CONSOLE=1 TERM_CHILD=1 INTERVAL=0.5   QUEUE="download" bundle exec rake resque:work
small_jobs: env LOG_CONSOLE=1 TERM_CHILD=1 INTERVAL=0.5   QUEUE="indexing,sunspot,notification,mailer" bundle exec rake resque:work
migration_jobs: env LOG_CONSOLE=1 TERM_CHILD=1  QUEUE="migration" bundle exec rake resque:work