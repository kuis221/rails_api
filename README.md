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

4. Create a local_env.yml file inside the config folder with the following content (ask for the S3 KEYS to a teammate):
        AWS_S3_KEY_ID: ''
        AWS_S3_ACCESS_KEY: ''
        MEMCACHIER_SERVERS: 'localhost:11211'
        REDISTOGO_URL: 'redis://localhost:6379'

5. Make sure you have [PhantomJS](http://phantomjs.org/download.html):

  For MacOS, type:

        brew update && brew install phantomjs

  For Linux Download the correct package from [here](http://phantomjs.org/download.html) and copy to any folder in your $PATH

6. Install the required gems:

        bundle install

7. Create the local database

        rake db:create db:migrate


8. Run the local Solr server

        rake sunspot:solr:start

9. Insert the initial data

        rake db:seed

10. Run the tests to make sure everything works (optional)

        rake

11. Load some test data into the app

        rake db:populate:all

12. Reindex the data we just created

        rake sunspot:reindex

13. Stop the local Solr server because it will be executed on the next step

        rake sunspot:solr:stop

14. Copy the following text in the .env in the project's root folder:
    RACK_ENV=development
    RAILS_ENV=development
    PORT=5000
    TERM_CHILD=1

15. Start the local server

        foreman start -f Procfile.dev

16. Go to http://localhost:5100/ and you should be able to login using:

        Email: admin@brandscopic.com
        Password: Adminpass12

## Coding standards

In order to keep or code clean and with the best practices, we should try to always follow the community practices:

  * Ruby: [https://github.com/bbatsov/ruby-style-guide](https://github.com/bbatsov/ruby-style-guide)
  * Rails: [https://github.com/bbatsov/rails-style-guide](https://github.com/bbatsov/rails-style-guide)
  * JavaScript [https://github.com/airbnb/javascript](https://github.com/airbnb/javascript)
  * CoffeeScriot [https://github.com/polarmobile/coffeescript-style-guide](https://github.com/polarmobile/coffeescript-style-guide)

## Background Jobs

Our application makes use of background jobs for tasks that require some time to process or that doesn't really need to happen at real time, like Solr indexing, photos thumbnail generation, list exports generation, sending SMSs and e-mails, etc. For such purpose, we are using Resque+Redis, you can see the background jobs queue in your local environment by going to: http://localhost:5100/resque

## Memcachier

Memcache is also used in several places to speed the the application. If you want to enable it in your development environment, [follow this steps](https://github.com/cjaskot/brandscopic/wiki/Use-Memcached-in-development).

## Rebuilding the Solr index

Sometimes the data can come out of sync during the development phase. Fortunately
there is a command we can use to build the entire index.
       rake sunspot:solr:index
