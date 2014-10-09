class AddInitialDataForActivities < ActiveRecord::Migration
  def up
    ['POS Placement', 'Drink Feature', 'Menu Placement', 'Staff Training'].each do |at_name|
      at = ActivityType.create(name: at_name, active: true, company_id: 2)

      case at_name
      when 'POS Placement'
        FormField.create(name: 'Brand', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Brand', ordering: 1, required: false)
        FormField.create({ name: 'Marque', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Marque', ordering: 2, required: false, settings: { 'multiple' => true } }, without_protection: true)
        ff = FormField.create(name: 'Placement Type', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Dropdown', ordering: 3, required: false)
        ['Chalk board', 'Mirror', 'Rail mat', 'Wearable', 'Church key', 'Napkin caddie', 'Other'].each_with_index do |ffo_name, index|
          ff.options.create(name: ffo_name, ordering: index + 1)
        end
        ff = FormField.create(name: 'Category', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Dropdown', ordering: 4, required: false)
        ['Discounted Shot', 'Shot & Beer', 'Cocktail', 'In-House Speciality (infused, pickle back, etc.)', 'Other'].each_with_index do |ffo_name, index|
          ff.options.create(name: ffo_name, ordering: index + 1)
        end
        FormField.create(name: 'Quantity', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Number', ordering: 5, required: false)
        FormField.create(name: 'Description', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::TextArea', ordering: 6, required: false)

      when 'Drink Feature'
        ff = FormField.create(name: 'Feature Type', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Dropdown', ordering: 1, required: false)
        %w(Daily Weekly Other).each_with_index do |ffo_name, index|
          ff.options.create(name: ffo_name, ordering: index + 1)
        end
        ff = FormField.create(name: 'Supported by signage?', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Radio', ordering: 2, required: false)
        %w(Yes No).each_with_index do |ffo_name, index|
          ff.options.create(name: ffo_name, ordering: index + 1)
        end
        FormField.create(name: 'Description', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::TextArea', ordering: 3, required: false)

      when 'Menu Placement'
        FormField.create(name: 'Brand', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Brand', ordering: 1, required: false)
        FormField.create({ name: 'Marque', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Marque', ordering: 2, required: false, settings: { 'multiple' => true } }, without_protection: true)
        ff = FormField.create(name: 'Placement Type', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Dropdown', ordering: 3, required: false)
        %w(Permanent Seasonal Temporary).each_with_index do |ffo_name, index|
          ff.options.create(name: ffo_name, ordering: index + 1)
        end
        FormField.create(name: 'Price', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Number', ordering: 4, required: false)
        FormField.create(name: 'Drink Name', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::Text', ordering: 5, required: false)
        FormField.create(name: 'Description (Cocktail name, recipe, price, inspiration (if applicable))', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::TextArea', ordering: 6, required: false)

      when 'Staff Training'
        FormField.create(name: 'Brief description', fieldable_id: at.id, fieldable_type: 'ActivityType', type: 'FormField::TextArea', ordering: 1, required: false)
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
