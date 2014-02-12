# encoding: utf-8
# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require 'simplecov'
SimpleCov.start "rails" do
  add_filter 'lib/legacy'
end

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rails'
require 'capybara/poltergeist'
require 'database_cleaner'
require 'capybara-screenshot/rspec'

require 'support/brandscopic_spec_helpers'
include BrandscopiSpecHelpers

# Requires supporting ruby files with custom matchers and macros, etc,
# in spec/support/ and its subdirectories.
Dir[Rails.root.join("spec/support/**/*.rb")].each {|f| require f}

# Capybara.register_driver :poltergeist do |app|
#   Capybara::Poltergeist::Driver.new(app, {js_errors:true, port:44678+ENV['TEST_ENV_NUMBER'].to_i, phantomjs_options:['--proxy-type=none'], timeout:180})
# end

# Capybara.register_driver :selenium do |app|
#   Capybara::Selenium::Driver.new(app, :browser => :chrome)
# end

RSpec.configure do |config|
  # ## Mock Framework
  #
  # If you prefer to use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = false

  config.render_views

  config.formatter = 'Fuubar' unless ENV['CI'] || ENV['NOBAR']

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = true

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  #config.include Capybara::DSL, :type => :request
  config.include SignHelper, :type => :feature
  config.include RequestsHelper, :type => :feature
  config.include BrandscopiSpecHelpers

  config.before(:suite) do
    DatabaseCleaner.strategy = :deletion
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.logger = Rails.logger
  end

  config.before(:all) do
    DeferredGarbageCollection.start
  end

  config.after(:all) do
    DeferredGarbageCollection.reconsider
  end

  # config.before(:each) do
  #   if example.metadata[:js]
  #     DatabaseCleaner.strategy = :deletion
  #   elsif example.metadata[:strategy]
  #     DatabaseCleaner.strategy = example.metadata[:strategy]
  #   else
  #     DatabaseCleaner.strategy = :transaction
  #   end
  # end

  config.before(:each) do
    Rails.logger.debug "\n\n\n\n\n\n\n\n\n\n"
    Rails.logger.debug "**************************************************************************************"
    Rails.logger.debug "***** EXAMPLE: #{example.full_description}"
    Rails.logger.debug "**************************************************************************************"
    DatabaseCleaner.start
  end

  if ENV['CI']
    Capybara::Screenshot.autosave_on_failure = false
    config.after(:each) do
      # Save screenshot to Amazon S3 on failure when running on the CI server
      if Capybara.page.current_url != '' && example.exception
        filename_prefix = Capybara::Screenshot.filename_prefix_for(:rspec, example)
        saver = Capybara::Screenshot::Saver.new(Capybara, Capybara.page, true, filename_prefix)
        saver.save

        # Save it to S3
        s3 = AWS::S3.new
        bucket = s3.buckets[S3_CONFIGS['bucket_name']]
        obj = bucket.objects[File.basename(saver.screenshot_path)].write(File.open(saver.screenshot_path))
        example.metadata[:full_description] += "\n     Screenshot: #{obj.url_for(:read, :expires => 24*3600*100)}"
      end
    end
  end

  config.after(:each) do
    if example.metadata[:js]
      wait_for_ajax
      #Capybara.reset_sessions!
    end
    User.current = nil
    Time.zone = Rails.application.config.time_zone

    # Reset all KPIs values to nil
    ['events', 'promo_hours', 'impressions', 'interactions', 'impressions', 'interactions', 'samples', 'expenses', 'gender', 'age', 'ethnicity', 'photos', 'videos', 'surveys', 'comments'].each do |kpi|
      Kpi.instance_variable_set("@#{kpi}".to_sym, nil)
    end
    DatabaseCleaner.clean
  end

  # Capybara.javascript_driver = :webkit
  #Capybara.javascript_driver = :selenium
  Capybara.javascript_driver = :poltergeist
  Capybara.default_wait_time = 4

  Devise.stretches = 1
  #Rails.logger.level = 4
end
