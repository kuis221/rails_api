class CreateZipcodeLocationsTable < ActiveRecord::Migration
  def change
    create_table :zipcode_locations do |t|
      t.string :zipcode, unique: true, null: false
      t.point :lonlat, geographic: true
    end
  end
end
