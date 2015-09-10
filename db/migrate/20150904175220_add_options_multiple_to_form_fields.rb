class AddOptionsMultipleToFormFields < ActiveRecord::Migration
  def up
    add_column :form_fields, :multiple, :boolean
    FormField.reset_column_information
    FormField.where(type: 'FormField::LikertScale').where(capture_mechanism: 'radio').update_all(multiple: false)
    FormField.where(type: 'FormField::LikertScale').where(capture_mechanism: 'checkbox').update_all(multiple: true)
    remove_column :form_fields, :capture_mechanism
  end

  def down
    add_column :form_fields, :capture_mechanism, :string
    FormField.reset_column_information
    FormField.where(type: 'FormField::LikertScale').where(multiple: false).update_all(capture_mechanism: 'radio')
    FormField.where(type: 'FormField::LikertScale').where(multiple: true).update_all(capture_mechanism: 'checkbox')
    remove_column :form_fields, :multiple
  end
end
