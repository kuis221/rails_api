class CreateMarques < ActiveRecord::Migration
  def change
    create_table :marques do |t|
      t.references :brand
      t.string :name

      t.timestamps
    end
    add_index :marques, :brand_id

    # A couple of marques for Jameson Whiskey brand
    execute "INSERT INTO marques (brand_id, name, created_at, updated_at) VALUES (8, 'Base', now(), now())"
    execute "INSERT INTO marques (brand_id, name, created_at, updated_at) VALUES (8, 'Black Barrel', now(), now())"
  end
end
