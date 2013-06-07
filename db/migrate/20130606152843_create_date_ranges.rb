class CreateDateRanges < ActiveRecord::Migration
  def change
    create_table :date_ranges do |t|
      t.string :name
      t.text :description
      t.boolean :active, default: true
      t.references :company
      t.integer :created_by_id
      t.integer :updated_by_id

      t.timestamps
    end
  end
end
