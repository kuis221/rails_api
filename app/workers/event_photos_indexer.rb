class EventPhotosIndexer
  include Resque::Plugins::UniqueJob
  @queue = :indexing

  def self.perform(event_id)
    event = Event.find(event_id)
    Sunspot.index(event.photos)
  rescue
  end
end
