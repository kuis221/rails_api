require 'sunspot_test/rspec'

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
