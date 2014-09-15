require "sunspot/queue/helpers"

class IndexWorker
  extend ::Sunspot::Queue::Helpers
  include Resque::Plugins::UniqueJob
  @queue = :indexing

  def self.perform(klass, id)
    without_proxy do
      constantize(klass).find(id).solr_index
    end

  rescue Resque::TermException
      # if the worker gets killed, (when deploying for example)
      # re-enqueue the job so it will be processed when worker is restarted
      Resque.enqueue(IndexWorker, klass, id)

  # Try it again a few times in case of a connection issue before raising the error
  rescue Errno::ECONNRESET, Net::ReadTimeout, Net::ReadTimeout, Net::OpenTimeout => e
    tries -= 1
    if tries > 0
      sleep(3)
      retry
    else
      raise e
    end
  end
end