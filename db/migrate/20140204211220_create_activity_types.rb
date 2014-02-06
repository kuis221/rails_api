class CreateActivityTypes < ActiveRecord::Migration
  def change
    create_table :activity_types do |t|
      t.string :name
      t.text :description
      t.boolean :active, default: true
      t.references :company

      t.timestamps
    end
    add_index :activity_types, :company_id
  end
end
