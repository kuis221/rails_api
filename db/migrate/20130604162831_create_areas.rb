class CreateAreas < ActiveRecord::Migration
  def change
    create_table :areas do |t|
      t.string :name
      t.text :description
      t.boolean :active, default: true
      t.references :company
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end
    add_index :areas, :company_id
  end
end
