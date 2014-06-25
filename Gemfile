source 'https://rubygems.org'

ruby '2.1.2'

gem 'rails', '3.2.18'
gem "rack-timeout"

# Bundle edge Rails instead:
# gem 'rails', git: 'git://github.com/rails/rails.git'

gem 'pg'
gem 'devise'
gem 'devise_invitable', '~> 1.3.0'
gem "cancan", ">= 1.6.8"
gem "slim-rails"
gem "annotate", ">=2.5.0",  group: :development
gem "quiet_assets", ">= 1.0.1", group: :development
gem 'inherited_resources'
gem 'has_scope'
gem 'clerk'
gem 'rabl'
gem 'oj'
gem 'simple-navigation'
gem 'aasm'
gem 'countries'
gem "company_scoped", path: 'vendor/gems/company_scoped'
gem 'newrelic_rpm'
gem "paperclip", "~> 4.1"
gem "aws-sdk"
gem 'google_places'
gem 'validates_timeliness', '~> 3.0'
gem 'sunspot_rails'
gem 'sunspot_stats'
gem "sunspot-queue"
gem 'progress_bar', require: false
gem 'gctools'
gem 'unicorn-worker-killer'
gem "geocoder"
gem 'rubyzip'
gem 'redis'
gem "resque" #, require: "resque/server"
gem 'resque-loner'
gem 'resque-pool', '~> 0.4.0.rc2'
gem 'resque-timeout'
gem 'unread'
gem 'strong_parameters'
gem 'nearest_time_zone'
gem "memcachier"
gem 'rack-cache'
gem 'dalli'
gem 'kgio'
gem 'activerecord-postgres-hstore'  # Remove when upgrading to Rails4
gem 'postgres_ext' # gem added to allow arrays. Remove when upgrading to Rails4
gem 'apipie-rails'
gem 'heroku-resque-workers-scaler', github: 'guilleva/heroku-resque-workers-scaler'
gem 'twilio-ruby'

#For memory debugging
gem "oink"
#gem "allocation_stats"

# Gems that are only required for the web process, to prevent
# workers loading not needed libraries
group :web do
  gem 'activeadmin'
  gem "meta_search", '>= 1.1.0.pre'
  gem 'unicorn'
  gem 'simple_form'
  gem "nested_form"
end

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'
  gem "twitter-bootstrap-rails"
  # See https://github.com/sstephenson/execjs#readme for more supported runtimes

  gem 'uglifier', '>= 1.0.3'
end

gem 'jquery-rails'

group :test, :development do
  gem "spring"
  gem "spring-commands-rspec"
  gem "factory_girl_rails", "~> 4.3"
  gem "rspec"
  gem "rspec-rails" #, "~> 2.0"
  gem 'populator'
  gem 'sunspot_solr'
  gem 'timecop'
  gem 'faker'
end

group :test do
  gem "capybara"
  gem "rspec-mocks"
  #gem "capybara-webkit"
  gem "poltergeist"
  #gem 'selenium-webdriver'
  gem "email_spec", ">= 1.4.0"
  gem 'shoulda'
  gem 'launchy'
  gem "sunspot_test"
  gem 'resque_spec'
  gem 'simplecov', require: false
  gem 'capybara-screenshot'
  gem 'fuubar'
  gem 'database_cleaner'
  gem 'sms-spec', '~> 0.1.9'
end

gem 'airbrake'
  group :production do
end

# To use ActiveModel has_secure_password
# gem 'bcrypt-ruby', '~> 3.0.0'

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Use unicorn as the app server
# gem 'unicorn'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
