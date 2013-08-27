class EventDataIndexer
  @queue = :sunspot

  def self.perform(event_data_id)
    begin
      EventData.find(event_data_id).update_data
    rescue
    end
  end
end