class PhotoMigrationWorker
  @queue = :migration

  def self.perform(legacy_id, local_id)
    require 'legacy'

    legacy_event = Legacy::Event.find(legacy_id)
    event = ::Event.find(local_id)

    legacy_event.synch_photos(event)
  end
end
