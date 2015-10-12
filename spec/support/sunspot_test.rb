# require 'sunspot_test/rspec'

RSpec.configure do |c|
  SunspotTest.solr_startup_timeout = 60

  c.include SunspotMatchers

  c.before(:each) do
    SunspotTest.stub
  end

  c.before(:each, sunspot_matcher: true) do
    Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)
  end

  c.before(:each, search: true) do |example|
    if example.metadata[:search]
      SunspotTest.setup_solr
      Sunspot.remove_all!
      Sunspot.commit
    end
  end
end


# $original_sunspot_session = Sunspot.session

# RSpec.configure do |config|
#   config.before do
#     Sunspot.session = Sunspot::Rails::StubSessionProxy.new($original_sunspot_session)
#   end

#   config.before(:each, sunspot_matcher: true) do
#     Sunspot.session = SunspotMatchers::SunspotSessionSpy.new(Sunspot.session)
#   end

#   config.before :each, search: true do
#     Sunspot::Rails::Tester.start_original_sunspot_session
#     Sunspot.session = $original_sunspot_session
#     Sunspot.remove_all!
#     Sunspot.commit
#   end
# end

# $original_sunspot_session = Sunspot.session

# RSpec.configure do |config|
#   config.before do
#     Sunspot.session = Sunspot::Rails::StubSessionProxy.new($original_sunspot_session)
#   end

#   config.before :each, search: true do
#     Sunspot::Rails::Tester.start_original_sunspot_session
#     Sunspot.session = $original_sunspot_session
#     Sunspot.remove_all!
#   end
# end
