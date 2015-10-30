require 'sunspot/queue/helpers'

class IndexWorker
  extend ::Sunspot::Queue::Helpers
  include ::Sidekiq::Worker
  sidekiq_options queue: :indexing, retry: 3

  def perform(klass, id)
    IndexWorker.without_proxy do
      IndexWorker.constantize(klass).find(id).solr_index
    end
  end
end
