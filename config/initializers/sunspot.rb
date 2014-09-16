# We are not using delayed reindexing to reduce the delay on listings. For example, activating/deactivating items on the list


# To reindex using delayed job
# unless defined?($rails_rake_task) && $rails_rake_task && !Rake.application.top_level_tasks.include?('jobs:work')
#   require "sunspot/queue/delayed_job"
#   backend = Sunspot::Queue::DelayedJob::Backend.new
#   Sunspot.session = Sunspot::Queue::SessionProxy.new(Sunspot.session, backend)
# end


# To reindex using resque
if ENV['WEB'] && !Rails.env.test?
  require "sunspot/queue/resque"
  backend = Sunspot::Queue::Resque::Backend.new
  Sunspot.session = Sunspot::Queue::SessionProxy.new(Sunspot.session, backend)

  Sunspot::Queue.configure do |config|
    # Override default job classes
    config.index_job   = IndexWorker
  end
end


# Allow simple http authentication for Solr if SOLR_USERNAME and SOLR_PASSWORD env vars are configured
class RSolrWithSimpleAuth
  attr_reader :username
  attr_reader :password
  def initialize(username, password)
    @username = username
    @password = password
  end

  def connect(opts = {})
    RSolr::Client.new(AuthenticatedConnection.new(@username, @password), opts)
  end

  class AuthenticatedConnection < ::RSolr::Connection
    attr_reader :username
    attr_reader :password

    def initialize(username, password)
      @username = username
      @password = password
    end

    def auth_headers
      @_auth_headers ||= begin
        auth = ActionController::HttpAuthentication::Basic.encode_credentials(@username, @password)
        {
        'Authorization' => auth
        }
      end
    end

    def setup_raw_request(request_context)
      raw_request = super(request_context)
      auth_headers.each{|k, v| raw_request[k] = v}
      raw_request
    end
  end
end

if ENV['SOLR_USERNAME'] && ENV['SOLR_PASSWORD']
  Sunspot::Session.connection_class = RSolrWithSimpleAuth.new(ENV['SOLR_USERNAME'], ENV['SOLR_PASSWORD'])
end