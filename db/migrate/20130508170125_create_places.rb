class CreatePlaces < ActiveRecord::Migration
  def change
    create_table :places do |t|
      t.string :name
      t.string :reference, limit: 400
      t.string :place_id, limit: 100
      t.string :types
      t.string :formatted_address
      t.float :latitude
      t.float :longitude
      t.string :street_number
      t.string :route
      t.string :zipcode
      t.string :city
      t.string :state
      t.string :country

      t.timestamps
    end

    add_index :places, :reference
  end
end
