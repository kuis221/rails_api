# encoding: utf-8
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'
require 'spec_helper'
require 'simplecov'
SimpleCov.start "rails" do
  add_filter 'lib/legacy'
end

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'shoulda/matchers'
require 'capybara/rails'
require 'capybara/poltergeist'
require 'database_cleaner'
require 'capybara-screenshot'
require 'capybara-screenshot/rspec'
require 'sms-spec'

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

include BrandscopiSpecHelpers

# Checks for pending migrations before tests are run.
# If you are not using ActiveRecord, you can remove this line.
ActiveRecord::Migration.maintain_test_schema!

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  #config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!

  config.render_views

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false


  #config.include Capybara::DSL, :type => :request
  config.include SignHelper, :type => :feature
  config.include RequestsHelper, :type => :feature

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.logger = Rails.logger
  end

  config.before(:each) do |example|
    #Resque::Worker.stub(:working).and_return([])
    allow(Resque::Worker).to receive_messages(:working => [])
  end

  config.around(:each) do |example|
    Rails.logger.debug "\n\n\n\n\n\n\n\n\n\n"
    Rails.logger.debug "**************************************************************************************"
    Rails.logger.debug "***** EXAMPLE: #{example.full_description}"
    Rails.logger.debug "**************************************************************************************"
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.after(:each) do |example|
    if example.metadata[:js]
      wait_for_ajax
    end
    User.current = nil
    Company.current = nil
    Time.zone = Rails.application.config.time_zone

    # Reset all KPIs values to nil
    ['events', 'promo_hours', 'impressions', 'interactions', 'impressions', 'interactions', 'samples', 'expenses', 'gender', 'age', 'ethnicity', 'photos', 'videos', 'surveys', 'comments'].each do |kpi|
      Kpi.instance_variable_set("@#{kpi}".to_sym, nil)
    end
  end

  config.include(SmsSpec::Helpers)
  config.include(SmsSpec::Matchers)

  SmsSpec.driver = :"twilio-ruby" #this can be any available sms-spec driver
end
