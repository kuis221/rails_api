# effected by race-condition: first process may boot slower the second
# either sleep a bit or use a lock for example File.lock
#

if ENV.key?('TEST_ENV_NUMBER')
  def launch_solr
    puts '*' * 69
    puts '**** Starting solr test server. This should take a few seconds  *****'
    puts '*' * 69
    SunspotTest.setup_solr
  end

  def wait_until_solr_starts
    SunspotTest.send(:wait_until_solr_starts)
  end


  ParallelTests.first_process? ? launch_solr : wait_until_solr_starts
end
