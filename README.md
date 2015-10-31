## Welcome to Brandscopic


![build status](https://www.codeship.io/projects/c908d6c0-3f66-0131-c536-0e9a90f6062f/status?branch=master) Master Branch

![build status](https://www.codeship.io/projects/c908d6c0-3f66-0131-c536-0e9a90f6062f/status?branch=development) Development Branch

## Getting Started

1. At the command prompt, clone the project:

        git clone git@github.com:cjaskot/brandscopic.git

2. Change directory to <tt>brandscopic</tt> and start the web server:

        cd brandscopic

3. Create a database.yml file inside the config folder with the following content:

        development:
          adapter: postgresql
          database: brandscopic_dev
          encoding: unicode
          username: <your_user_name>
          password:
          server: 127.0.0.1

        test:
          adapter: postgresql
          database: brandscopic_test
          encoding: unicode
          username: <your_user_name>
          password:
          server: 127.0.0.1
          min_messages: WARNING

4. Create a local_env.yml file inside the config folder with the following content (ask nicely for the S3 KEYS to a teammate):
        DATABASE_USER: <your PG username>
        DATABASE_PASSWORD: <your PG user password>
        AWS_S3_KEY_ID: ''
        AWS_S3_ACCESS_KEY: ''
        GOOGLE_API_KEY: ''
        S3_BUCKET_NAME: 'brandscopic-dev'
        MEMCACHIER_SERVERS: 'localhost:11211'
        REDISTOGO_URL: 'redis://localhost:6379'

5. Make sure you have [PhantomJS](http://phantomjs.org/download.html) version 1.9.X, version 2.0 does not support file attachments yet:

  For MacOS:
    (Note: In El Capitan as for Oct 2015 it's not possible to install it using brew, so download the correct version and install manually)

        brew update && brew install phantomjs

  For Linux Download the correct package from [here](http://phantomjs.org/download.html) and copy to any folder in your $PATH

6. Install the required gems:

        bundle install

7. Create the local database

        rake db:create db:migrate


8. Run the local Solr server

        rake sunspot:solr:start

9. Install [redis](http://redis.io/):
  For MacOS:

        brew install redis

  For Ubuntu:

        sudo apt-get install redis-server

        # Its started altogether with foreman, so we don't need it to be installed
        # as a service
        sudo update-rc.d redis-server disable

11. Start redis in another tab (we need it to run db:seed, it will be stoped after the next step)

        redis-server

12. Insert the initial data

        rake db:seed

13. Stop Solr and Redis(^C)

        rake sunspot:solr:stop

14. Run the tests to make sure everything works (optional) See the Running Tests section.


15. Load some test data into the app. This will create some users (all with the `Test1234` password), campaigns and some other stuff

        rake db:populate:all

   Reindex the data we just created

        rake sunspot:reindex

16. Stop the local Solr server because it will be executed on the next step

        rake sunspot:solr:stop

17. Copy the following text in the .env in the project's root folder:
    RACK_ENV=development
    RAILS_ENV=development
    PORT=5000
    TERM_CHILD=1

18. Install foreman

        gem install foreman

19. Star the required processes, including rails server using foreman with the Procfile.dev (because Procfile has stuff for production)

        foreman start -f Procfile.dev

20. Go to http://localhost:5100/ and you should be able to login using:

        Email: admin@brandscopic.com
        Password: Adminpass12

## Brandscopic Admin Backend

We have a basic backend for some admin tasks that can be accessed at http://localhost:5100/admin and login in as the AdminUser user that was created in the seed task.

## Coding standards

In order to keep or code clean and with the best practices, we should try to always follow the community practices:

  * Ruby: [https://github.com/bbatsov/ruby-style-guide](https://github.com/bbatsov/ruby-style-guide)
  * Rails: [https://github.com/bbatsov/rails-style-guide](https://github.com/bbatsov/rails-style-guide)
  * JavaScript [https://github.com/airbnb/javascript](https://github.com/airbnb/javascript)
  * CoffeeScriot [https://github.com/polarmobile/coffeescript-style-guide](https://github.com/polarmobile/coffeescript-style-guide)

## Background Jobs

Our application makes use of background jobs for tasks that require some time to process or that doesn't really need to happen at real time, like Solr indexing, photos thumbnail generation, list exports generation, sending SMSs and e-mails, etc. For such purpose, we are using Sidekiq+Redis, you can see the background jobs queue in your local environment by going to: http://localhost:5100/_bgjobs

## Memcachier

Memcache is also used in several places to speed the the application but it's not required for development. If you want to enable it in your development environment, [follow this steps](https://github.com/cjaskot/brandscopic/wiki/Use-Memcached-in-development).

## Rebuilding the Solr index

Sometimes the data can come out of sync during the development phase. Fortunately
there is a command we can use to build the entire index.
       rake sunspot:solr:index

## Running the tests

You can run the tests by simple running `rake`, but you can speed it up a little with parallel_test by running `DISABLE_SPRING=1 rake "parallel:spec"`, but default, it will load as many process as CPUs you machine have. Since 8 processes might be a lot


## Setting parallel_tests for the first use

  Create additional database(s)

        rake parallel:create

  Copy development schema (repeat after migrations)

        rake parallel:prepare

## Running parallel tests!

        rake parallel:spec

