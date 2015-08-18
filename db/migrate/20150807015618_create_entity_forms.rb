class CreateEntityForms < ActiveRecord::Migration
  def change
    create_table :entity_forms do |t|
      t.string :entity
      t.integer :entity_id, default: nil
      t.references :company
      t.timestamps
    end
    add_index :entity_forms, [:entity, :company_id], unique: true
  end
end
