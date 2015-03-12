class CreateDataExtracts < ActiveRecord::Migration
  def change
    create_table :data_extracts do |t|
      t.string :type
      t.references :company, index: true
      t.boolean :active
      t.string :sharing
      t.string :name
      t.text :description
      t.text :filters
      t.text :columns
      t.references :created_by, index: true
      t.references :updated_by, index: true

      t.timestamps
    end
  end
end
