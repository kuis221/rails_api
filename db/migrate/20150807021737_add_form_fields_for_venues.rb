class AddFormFieldsForVenues < ActiveRecord::Migration
  def up
    f = EntityForm.create(entity: 'Venue', company_id: 14 )
    f.form_fields << FormField::TextArea.new(name: 'Account Overview', ordering: 1)
    f.form_fields << FormField::Text.new(name: 'Pernod Ricard Contact (Account Manager)', ordering: 2)
    f.form_fields << FormField::Text.new(name: 'Manager Name/Key Contact', ordering: 3)
    field_checkbox = FormField::Checkbox.new(name: 'Account Segmentation', ordering: 4)
    f.form_fields << field_checkbox
    field_checkbox.options << FormFieldOption.new(name: 'Restaurant', ordering: 1, option_type: 'option')
    field_checkbox.options << FormFieldOption.new(name: 'Low Energy Bar', ordering: 2, option_type: 'option')
    field_checkbox.options << FormFieldOption.new(name: 'High Energy Bar', ordering: 3, option_type: 'option')
    field_checkbox.options << FormFieldOption.new(name: 'Nightclub', ordering: 4, option_type: 'option')
    field_checkbox.options << FormFieldOption.new(name: 'Mainstream Account', ordering: 5, option_type: 'option')
    field_checkbox.options << FormFieldOption.new(name: 'Premium Account', ordering: 6, option_type: 'option')
    field_checkbox.options << FormFieldOption.new(name: 'Leading Account', ordering: 7, option_type: 'option')
    field_checkbox.options << FormFieldOption.new(name: 'Iconic Account', ordering: 8, option_type: 'option')
    field_percentage = FormField::Percentage.new(name: 'Clientele', ordering: 5)
    f.form_fields << field_percentage
    field_percentage.options << FormFieldOption.new(name: '18-24yo', ordering: 1, option_type: 'option')
    field_percentage.options << FormFieldOption.new(name: 'Lads 25-35yo', ordering: 2, option_type: 'option')
    field_percentage.options << FormFieldOption.new(name: 'Dudes', ordering: 3, option_type: 'option')
    field_percentage.options << FormFieldOption.new(name: '35+', ordering: 4, option_type: 'option')
  end
  def down
  end
end
