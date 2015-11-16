class EventDataIndexer
  include Sidekiq::Worker
  sidekiq_options queue: :indexing, retry: 3

  def perform(event_data_id)
    data = EventData.find(event_data_id)
    data.update_data
    data.save
    Sunspot.index(data.event)
  end
end
