class EventDataIndexer
  include Resque::Plugins::UniqueJob
  @queue = :indexing

  def self.perform(event_data_id)
    data = EventData.find(event_data_id).update_data
    data.save
    Sunspot.index(data.event)
  end
end