class AddCommonDenominatorsToAreas < ActiveRecord::Migration
  def change
    add_column :areas, :common_denominators, :text
  end
end
