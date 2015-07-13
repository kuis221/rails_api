class AddPhotosCountToEventData < ActiveRecord::Migration
  def change
    add_column :event_data, :photos_count, :integer, default: 0
  end
end
