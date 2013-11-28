# This file is copied to spec/ when you run 'rails generate rspec:install'
ENV["RAILS_ENV"] ||= 'test'

require 'simplecov'
SimpleCov.start "rails"

require File.expand_path("../../config/environment", __FILE__)
require 'rspec/rails'
require 'rspec/autorun'
require 'capybara/rails'
require 'sunspot_test/rspec'
#require 'capybara/poltergeist'

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
  config.use_transactional_fixtures = true

  config.render_views

  # If true, the base class of anonymous controllers will be inferred
  # automatically. This will be the default behavior in future versions of
  # rspec-rails.
  config.infer_base_class_for_anonymous_controllers = false

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  #     --seed 1234
  config.order = "random"

  config.include Capybara::DSL, :type => :request
  config.include SignHelper, :type => :request
  config.include RequestsHelper, :type => :request

  config.before(:all) do
    DeferredGarbageCollection.start
  end
  config.after(:all) do
    DeferredGarbageCollection.reconsider
  end


  # Capybara.javascript_driver = :webkit
  Capybara.javascript_driver = :selenium
  Capybara.default_wait_time = 5

  SunspotTest.solr_startup_timeout = 60 # will wait 60 seconds for the solr process to start

  Devise.stretches = 1
  #Rails.logger.level = 4
end

def sign_in_as_user
  company = FactoryGirl.create(:company)
  #role = FactoryGirl.create(:role, company: company, active: true, name: "Current User Role")
  role = company.roles.first
  user = company.company_users.first.user
  user.current_company = company
  user.ensure_authentication_token
  user.update_attributes(FactoryGirl.attributes_for(:user).reject{|k,v| ['password','password_confirmation','email'].include?(k.to_s)}, without_protection: true)
  sign_in user
  User.current = user
end

def set_event_results(event, results, autosave = true)
  event.result_for_kpi(Kpi.impressions).value = results[:impressions] if results.has_key?(:impressions)
  event.result_for_kpi(Kpi.interactions).value = results[:interactions] if results.has_key?(:interactions)
  event.result_for_kpi(Kpi.samples).value = results[:samples] if results.has_key?(:samples)
  values = event.result_for_kpi(Kpi.gender)
  values.detect{|r| r.kpis_segment.text == 'Male'}.value = results[:gender_male] if results.has_key?(:gender_male)
  values.detect{|r| r.kpis_segment.text == 'Female'}.value = results[:gender_female] if results.has_key?(:gender_female)

  values = event.result_for_kpi(Kpi.ethnicity)
  values.detect{|r| r.kpis_segment.text == 'Asian'}.value = results[:ethnicity_asian] if results.has_key?(:ethnicity_asian)
  values.detect{|r| r.kpis_segment.text == 'Native American'}.value = results[:ethnicity_native_american] if results.has_key?(:ethnicity_native_american)
  values.detect{|r| r.kpis_segment.text == 'Black / African American'}.value = results[:ethnicity_black] if results.has_key?(:ethnicity_black)
  values.detect{|r| r.kpis_segment.text == 'Hispanic / Latino'}.value = results[:ethnicity_hispanic] if results.has_key?(:ethnicity_hispanic)
  values.detect{|r| r.kpis_segment.text == 'White'}.value = results[:ethnicity_white] if results.has_key?(:ethnicity_white)

  values = event.result_for_kpi(Kpi.age)
  values.detect{|r| r.kpis_segment.text == '< 12'}.value = results[:age_12] if results.has_key?(:age_12)
  values.detect{|r| r.kpis_segment.text == '12 – 17'}.value = results[:age_12_17] if results.has_key?(:age_12_17)
  values.detect{|r| r.kpis_segment.text == '18 – 24'}.value = results[:age_18_24] if results.has_key?(:age_18_24)
  values.detect{|r| r.kpis_segment.text == '25 – 34'}.value = results[:age_25_34] if results.has_key?(:age_25_34)
  values.detect{|r| r.kpis_segment.text == '35 – 44'}.value = results[:age_35_44] if results.has_key?(:age_35_44)
  values.detect{|r| r.kpis_segment.text == '45 – 54'}.value = results[:age_45_54] if results.has_key?(:age_45_54)
  values.detect{|r| r.kpis_segment.text == '55 – 64'}.value = results[:age_55_64] if results.has_key?(:age_55_64)
  values.detect{|r| r.kpis_segment.text == '65+'}.value = results[:age_65] if results.has_key?(:age_65)

  event.save if autosave
end

class ActiveRecord::Base
  mattr_accessor :shared_connection
  @@shared_connection = nil

  def self.connection
    @@shared_connection || retrieve_connection
  end
end

# Use: it { should accept_nested_attributes_for(:association_name).and_accept({valid_values => true}).but_reject({ :reject_if_nil => nil })}
RSpec::Matchers.define :accept_nested_attributes_for do |association|
  match do |model|
    @model = model
    @nested_att_present = model.respond_to?("#{association}_attributes=".to_sym)
    if @nested_att_present && @reject
      model.send("#{association}_attributes=".to_sym,[@reject])
      @reject_success = model.send("#{association}").empty?
    end
    if @nested_att_present && @accept
      model.send("#{association}_attributes=".to_sym,[@accept])
      @accept_success = ! (model.send("#{association}").empty?)
    end
    @nested_att_present && ( @reject.nil? || @reject_success ) && ( @accept.nil? || @accept_success )
  end

  failure_message_for_should do
    messages = []
    messages << "expected #{@model.class} to accept nested attributes for #{association}" unless @nested_att_present
    messages << "expected #{@model.class} to reject values #{@reject.inspect} for association #{association}" unless @reject_success
    messages << "expected #{@model.class} to accept values #{@accept.inspect} for association #{association}" unless @accept_success
    messages.join(", ")
  end

  description do
    desc = "accept nested attributes for #{expected}"
    if @reject
      desc << ", but reject if attributes are #{@reject.inspect}"
    end
  end

  chain :but_reject do |reject|
    @reject = reject
  end

  chain :and_accept do |accept|
    @accept = accept
  end
end

# Forces all threads to share the same connection. This works on
# Capybara because it starts the web server in a thread.
ActiveRecord::Base.shared_connection = ActiveRecord::Base.connection#