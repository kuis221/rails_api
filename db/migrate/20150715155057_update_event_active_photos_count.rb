class UpdateEventActivePhotosCount < ActiveRecord::Migration
  def change
    attachable_id_and_counts = AttachedAsset.where(attachable_type: 'Event', asset_type: 'photo', active: true).group('attachable_id').count
    Event.transaction do
      attachable_id_and_counts.each do |event_id, count|
        Event.where(id: event_id).update_all("active_photos_count = #{count}")
      end
    end
  end
end
