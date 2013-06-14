class AddAdministrativeLevelsToPlaces < ActiveRecord::Migration
  def change
    add_column :places, :administrative_level_1, :string
    add_column :places, :administrative_level_2, :string
    Place.update_all('administrative_level_1=state')
    Place.all.each{|p| p.update_info_from_api }
  end
end
