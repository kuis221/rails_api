class CreateFormFields < ActiveRecord::Migration
  def change
    create_table :form_fields do |t|
      t.references :fieldable, polymorphic: true
      t.string :name
      t.string :type
      t.text :settings
      t.integer :ordering
      t.boolean :required

      t.timestamps
    end
    add_index :form_fields, [:fieldable_id, :fieldable_type]
  end
end
