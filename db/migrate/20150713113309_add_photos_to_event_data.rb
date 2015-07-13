class AddPhotosToEventData < ActiveRecord::Migration
  def change
    add_column :event_data, :photos, :integer, default: 0
  end
end
