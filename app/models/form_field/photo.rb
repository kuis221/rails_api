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

class FormField::Photo < FormField
  def field_options(result)
    { as: :attached_asset,
      label: self.name,
      field_id: self.id, options: self.settings,
      file_types: '(\.|\/)(gif|jpe?g|png)$',
      browse_legend: 'inputs.attached_asset.select_file.photo',
      required: self.required, input_html: {
        value: result.value, class: field_classes,
        required: (self.required? ? 'required' : nil) } }
  end

  def field_classes
    []
  end

  def is_attachable?
    true
  end

  def format_html(result)
    if result.attached_asset.present? && result.attached_asset.processed?
      "<a href=\"#{result.attached_asset.download_url}\" title=\"Download\"><img src=\"#{result.attached_asset.file.url(:thumbnail)}\" alt=\"\" /></a>".html_safe
    elsif result.attached_asset.present?
      "The photo is being processed. It will be available soon.."
    end
  end

  def validate_result(result)
    super
    if result.attached_asset.present? && !result.attached_asset.valid?
      result.errors.add :value, "is not valid"
    end
  end
end