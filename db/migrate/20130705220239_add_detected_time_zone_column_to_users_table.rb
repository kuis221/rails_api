class AddDetectedTimeZoneColumnToUsersTable < ActiveRecord::Migration
  def change
    add_column :users, :detected_time_zone, :string
  end
end
