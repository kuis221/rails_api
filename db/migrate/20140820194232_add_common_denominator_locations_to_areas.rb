class AddCommonDenominatorLocationsToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :common_denominators_locations, :integer, array: true, default: []
    add_index  :areas, :common_denominators_locations, using: 'gin'
    Area.find_each{|a| a.send(:update_common_denominators) }
  end
end
