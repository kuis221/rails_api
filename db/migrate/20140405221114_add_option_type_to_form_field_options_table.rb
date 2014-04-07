class AddOptionTypeToFormFieldOptionsTable < ActiveRecord::Migration
  def change
    add_column :form_field_options, :option_type, :string
    add_index :form_field_options, [:form_field_id, :option_type]
    FormFieldOption.update_all(option_type: 'option')
  end
end
