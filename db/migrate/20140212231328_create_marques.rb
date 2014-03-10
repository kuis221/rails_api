class CreateMarques < ActiveRecord::Migration
  def change
    create_table :marques do |t|
      t.references :brand
      t.string :name

      t.timestamps
    end
    add_index :marques, :brand_id
    # A couple of marques for Jameson Whiskey brand
    if brand = Brand.find_by_name('Jameson Whiskey')
      brand.marques.create({name: 'Base'}, without_protection: true)
      brand.marques.create({name: 'Black Barrel'}, without_protection: true)
    end
  end
end
