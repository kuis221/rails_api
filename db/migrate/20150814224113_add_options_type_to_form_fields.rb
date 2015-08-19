class AddOptionsTypeToFormFields < ActiveRecord::Migration
  def up
    add_column :form_fields, :capture_mechanism, :string
    FormField.reset_column_information
    FormField.where(type: 'FormField::LikertScale').update_all(capture_mechanism: 'radio')
  end

  def down
    remove_column :form_fields, :capture_mechanism
  end
end
