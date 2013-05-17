class CreateBrands < ActiveRecord::Migration
  def change
    create_table :brands do |t|
      t.string :name
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end
  end
end
