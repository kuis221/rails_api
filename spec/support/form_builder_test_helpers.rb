
module FormBuilderTestHelpers
  def text_area_field
    find('.fields-wrapper .field', text: 'Paragraph')
  end

  def number_field
    find('.fields-wrapper .field', text: 'Number')
  end

  def section_field
    find('.fields-wrapper .field', text: 'Section')
  end

  def price_field
    find('.fields-wrapper .field', text: 'Price')
  end

  def text_field
    find('.fields-wrapper .field', text: 'Single line text')
  end

  def dropdown_field
    find('.fields-wrapper .field', text: 'Dropdown')
  end

  def radio_field
    find('.fields-wrapper .field', text: 'Multiple Choice')
  end

  def checkbox_field
    find('.fields-wrapper .field', text: 'Checkboxes')
  end

  def date_field
    find('.fields-wrapper .field', text: 'Date')
  end

  def time_field
    find('.fields-wrapper .field', text: 'Time')
  end

  def brand_field
    find('.fields-wrapper .field', text: 'Brand')
  end

  def place_field
    find('.fields-wrapper .field', text: 'Place')
  end

  def marque_field
    find('.fields-wrapper .field', text: 'Marque')
  end

  def percentage_field
    find('.fields-wrapper .field', text: 'Percent')
  end

  def photo_field
    find('.fields-wrapper .field', text: 'Photo')
  end

  def attachment_field
    find('.fields-wrapper .field', text: 'Attachment')
  end

  def calculation_field
    find('.fields-wrapper .field', text: 'Calculation')
  end

  def likert_scale_field
    find('.fields-wrapper .field', text: 'Likert scale')
  end

  def kpi_field(kpi)
    find('.fields-wrapper .field', text: kpi.name)
  end

  def module_field(module_name)
    find('.fields-wrapper .module', text: module_name)
  end

  def module_section(name)
    find('.form-section.module', text: name.upcase + ' MODULE')
  end

  def form_builder
    find('.form-fields')
  end

  def form_field_settings_for(field_name)
    field = field_name
    field = form_field(field_name) if field_name.is_a?(String)
    field.trigger 'click'
    find('.field-attributes-panel')
  end

  def form_field(field_name)
    field = nil
    form_builder.all('.field').each do |wrapper|
      field = wrapper if wrapper.all('label.control-label', text: field_name).count > 0
    end
    fail "Field #{field_name} not found" if field.nil?
    field
  end

  def form_section(section_name)
    field = nil
    form_builder.all('.field').each do |wrapper|
      field = wrapper if wrapper.all('h3', text: section_name).count > 0
    end
    fail "Section #{section_name} not found" if field.nil?
    field
  end

  def toggle_collapsible(name)
    find('.fields-wrapper .accordion-toggle', text: name).trigger('click')
  end
end
