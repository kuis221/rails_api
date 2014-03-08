class CreateActivityResults < ActiveRecord::Migration
  def change
    create_table :activity_results do |t|
      t.references :activity
      t.references :form_field
      t.text :value

      t.timestamps
    end
    add_index :activity_results, :activity_id
    add_index :activity_results, :form_field_id
    add_index :activity_results, [:activity_id, :form_field_id]
  end
end
