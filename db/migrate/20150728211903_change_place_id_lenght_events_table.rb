class ChangePlaceIdLenghtEventsTable < ActiveRecord::Migration
  def change
    change_column :places, :place_id, :string, limit: 200
  end
end
