class AddActivePhotosCountToEvents < ActiveRecord::Migration
  def change
    add_column :events, :active_photos_count, :integer, default: 0
  end
end
