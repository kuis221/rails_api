class AddLonlatColumnToPlacesTable < ActiveRecord::Migration
  def change
    add_column :places, :lonlat, :point, geographic: true
    Place.where.not(latitude: nil).where.not(latitude: '').find_each do |p|
      p.update_column(:lonlat,  "POINT(#{p[:longitude]} #{p[:latitude]})")
    end
    remove_column :places, :latitude
    remove_column :places, :longitude
  end
end
