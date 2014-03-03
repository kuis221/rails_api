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

class FormField < ActiveRecord::Base
  belongs_to :fieldable, polymorphic: true

  has_many :options, class_name: 'FormFieldOption', dependent: :destroy, inverse_of: :form_field

  serialize :settings

  validates :fieldable_id, presence: true, numericality: true
  validates :fieldable_type, presence: true
  validates :name, presence: true
  validates :type, presence: true
  validates :ordering, presence: true, numericality: true

  def field_options(result)
    {as: :string}
  end

  def field_classes
    ['input-xlarge']
  end

  def store_value(value)
    value
  end

  def format_html(result)
    result.value
  end

  def css_class
    self.class.name.underscore.gsub('/', '_')
  end
end
