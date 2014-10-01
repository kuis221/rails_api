require 'sunspot_test/rspec'

RSpec.configure do |c|
  SunspotTest.solr_startup_timeout = 60

  c.before(:each) do
    SunspotTest.stub
  end

  c.before(:each, search: true) do
    SunspotTest.setup_solr
    Sunspot.remove_all!
    Sunspot.commit
  end
end
