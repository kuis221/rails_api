class FixAreasLocations < ActiveRecord::Migration
  def change
    Place.where("types LIKE '%natural_feature%'").update_all(is_location: false)
    Area.all.each do |area|
      area.send(:update_common_denominators)
      area.save
      Rails.cache.delete("area_locations_#{area.id}")
    end
  end
end
