class EventPhotosIndexer
  @queue = :sunspot

  def self.perform(event_id)
    begin
      event = Event.find(event_id)
      Sunspot.index(event.photos)
    rescue
    end
  end
end