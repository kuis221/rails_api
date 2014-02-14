class UpdateLocations < ActiveRecord::Migration
  def up
    Place.find_each{|p| p.save }
  end

  def down
  end
end
