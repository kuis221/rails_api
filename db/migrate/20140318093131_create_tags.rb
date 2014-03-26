class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags do |t|
      t.string :name
      t.references :company
      t.integer :created_by_id
      t.integer :updated_by_id
      t.timestamps
    end
  end
end
