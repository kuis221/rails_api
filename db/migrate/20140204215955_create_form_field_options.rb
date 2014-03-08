class CreateFormFieldOptions < ActiveRecord::Migration
  def change
    create_table :form_field_options do |t|
      t.references :form_field
      t.string :name
      t.integer :ordering

      t.timestamps
    end
    add_index :form_field_options, :form_field_id
  end
end
