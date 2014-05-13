# == Schema Information
#
# Table name: form_fields
#
#  id             :integer          not null, primary key
#  fieldable_id   :integer
#  fieldable_type :string(255)
#  name           :string(255)
#  type           :string(255)
#  settings       :text
#  ordering       :integer
#  required       :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#

class FormField::Checkbox < FormField
  def field_options(result)
    {as: :check_boxes, collection: self.options.order(:ordering), label: self.name, field_id: self.id, options: self.settings, required: self.required, input_html: {value: result.value, required: (self.required? ? 'required' : nil)}}
  end

  def format_html(result)
    unless result.value.nil? || result.value.empty?
      self.options.where(id: result.value).pluck(:name).join(', ')
    end
  end

  def is_hashed_value?
    true
  end

  def is_optionable?
    true
  end

  def store_value(values)
    if values.is_a?(Hash)
      values
    elsif values.is_a?(Array)
      Hash[values.reject{|v| v.nil? || (v.respond_to?(:empty?) && v.empty?) }.map{|v| [v, 1] }]
    else
      {values => nil}
    end
  end
end
