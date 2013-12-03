class EventDataIndexer
  include Resque::Plugins::UniqueJob
  @queue = :indexing

  def self.perform(event_data_id)
    data =  EventData.find(event_data_id).update_data.save
    Resque.reindex(data.event)
  end
end