source 'https://rubygems.org'

ruby ENV['CUSTOM_RUBY_VERSION'] || '2.1.3'

gem 'rails', '4.1.5'
gem 'rails-observers'
gem 'activerecord-session_store'
gem "rack-timeout"

# Bundle edge Rails instead:
# gem 'rails', git: 'git://github.com/rails/rails.git'

gem 'pg'
gem 'devise'
gem 'devise_invitable', '~> 1.3.0'
gem 'cancancan', '~> 1.9'
gem "slim-rails"
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
gem 'timeliness'
gem 'american_date'
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
gem 'resque-timeout'
gem 'resque_mailer'
gem 'unread'
gem 'nearest_time_zone'
gem "memcachier"
gem 'dalli'
gem 'apipie-rails'
gem 'heroku-resque-workers-scaler', github: 'guilleva/heroku-resque-workers-scaler'
gem 'twilio-ruby'
gem "nested_form"
gem 'wicked_pdf'

#For memory debugging
#gem "allocation_stats"

group :development do
  gem "rack-livereload"
  gem "guard-livereload", :require => false
  gem "annotate", ">=2.5.0"
  gem "quiet_assets", ">= 1.0.1"
  gem "oink"
end

# Gems that are only required for the web process, to prevent
# workers loading not needed libraries
group :web do
  gem 'font_assets', path: 'vendor/gems/font_assets'
  gem 'activeadmin', github: 'activeadmin/active_admin'
  gem 'unicorn'
  gem 'simple_form'
  gem 'country_select', '2.0.0.rc1'
end

# Gems used only for assets and not required
# in production environments by default.
gem 'sass-rails', '~> 4.0.3'
gem 'coffee-rails'
gem 'uglifier', '>= 1.3.0'

gem 'jquery-rails'

group :test, :development do
  gem "spring"
  gem "spring-commands-rspec"
  gem "factory_girl_rails"
  gem "rspec-rails", '~> 3.0.0'
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
  gem 'shoulda-matchers', require: false
  #gem 'launchy'
  gem "sunspot_test"
  gem 'resque_spec'
  gem 'simplecov', require: false
  gem 'capybara-screenshot'
  gem 'fuubar', '2.0.0'
  gem 'database_cleaner'
  #gem 'sms-spec', '~> 0.1.9'
  gem 'sms-spec'
  gem 'pdf-reader'
end

group :production do
  gem 'airbrake'
  gem 'rails_12factor'
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
