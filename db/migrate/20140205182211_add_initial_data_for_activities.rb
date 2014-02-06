class AddInitialDataForActivities < ActiveRecord::Migration
  def up
    ['POS Placement', 'Drink Feature', 'Menu Placement', 'Staff Training'].each do |at_name|
      at = ActivityType.create({name: at_name, active: true, company_id: 2}, without_protection: true)

      case at_name
      when 'POS Placement'
        ff = FormField.create({name: 'Placement Type', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Dropdown', ordering: 1, required: true}, without_protection: true)
        ['Chalk board', 'Mirror', 'Rail mat', 'Wearable', 'Church key', 'Napkin caddie', 'Other'].each_with_index do |ffo_name, index|
          ff.options.create({name: ffo_name, ordering: index+1}, without_protection: true)
        end
        FormField.create({name: 'Quantity', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Number', ordering: 2, required: true}, without_protection: true)

      when 'Drink Feature'
        ff = FormField.create({name: 'Feature Type', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Dropdown', ordering: 1, required: true}, without_protection: true)
        ['Daily', 'Weekly', 'Other'].each_with_index do |ffo_name, index|
          ff.options.create({name: ffo_name, ordering: index+1}, without_protection: true)
        end
        ff = FormField.create({name: 'Supported by signage?', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Radio', ordering: 2, required: true}, without_protection: true)
        ['Yes', 'No'].each_with_index do |ffo_name, index|
          ff.options.create({name: ffo_name, ordering: index+1}, without_protection: true)
        end

      when 'Menu Placement'
        ff = FormField.create({name: 'Placement Type', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Dropdown', ordering: 1, required: true}, without_protection: true)
        ['Permanent', 'Seasonal', 'Temporary'].each_with_index do |ffo_name, index|
          ff.options.create({name: ffo_name, ordering: index+1}, without_protection: true)
        end
        FormField.create({name: 'Description (Cocktail name, cocktail recipe, price, cocktail inspiration (if applicable))', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::TextArea', ordering: 2, required: true}, without_protection: true)

      when 'Staff Training'
        FormField.create({name: 'Brief description', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::TextArea', ordering: 1, required: true}, without_protection: true)
      end
    end
  end

  def down
    ActivityType.destroy_all
    FormField.destroy_all

    ActivityType.connection.execute('ALTER SEQUENCE activity_types_id_seq RESTART WITH 1')
    FormField.connection.execute('ALTER SEQUENCE form_fields_id_seq RESTART WITH 1')
    FormFieldOption.connection.execute('ALTER SEQUENCE form_field_options_id_seq RESTART WITH 1')
  end
end
