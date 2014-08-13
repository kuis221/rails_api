## Welcome to Brandscopic


![build status](https://www.codeship.io/projects/c908d6c0-3f66-0131-c536-0e9a90f6062f/status?branch=master) Master Branch

![build status](https://www.codeship.io/projects/c908d6c0-3f66-0131-c536-0e9a90f6062f/status?branch=development) Development Branch

## Getting Started

1. At the command prompt, clone the project:

        git clone git@github.com:cjaskot/brandscopic.git

2. Change directory to <tt>brandscopic</tt> and start the web server:

        cd brandscopic

4. Create a database.yml file inside the config folder with the following content:

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

3. Make sure you have [PhantomJS](http://phantomjs.org/download.html):

  For MacOS, type:

        brew update && brew install phantomjs

  For Linux Download the correct package from [here](http://phantomjs.org/download.html) and copy to any folder in your $PATH

4. Install the required gems:

        bundle install

5. Create the local database

        rake db:create db:migrate


6. Run the local Solr server

        rake sunspot:solr:start

7. Insert the initial data

        rake db:seed

8. Run the tests to make sure everything works (optional)

        rake

9. Load some test data into the app

        rake db:populate:all

10. Reindex the data we just created

        rake sunspot:reindex

11. Stop the local Solr server because it will be executed on the next step

        rake sunspot:solr:stop

12. Copy the following text in the .env in the project's root folder:
    RACK_ENV=development
    RAILS_ENV=development
    PORT=5000
    REDISTOGO_URL=redis://localhost:6379
    TERM_CHILD=1

13. Start the local server

        foreman start -f Procfile.dev

14. Go to http://localhost:5100/ and you should be able to login using:

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
