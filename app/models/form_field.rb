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
#  kpi_id         :integer
#

class FormField < ActiveRecord::Base
  MIN_OPTIONS_ALLOWED = 1
  MIN_STATEMENTS_ALLOWED = 1
  VALID_RANGE_FORMATS = %w(digits characters words value)
  belongs_to :fieldable, polymorphic: true

  has_many :options, ->{ order('form_field_options.ordering ASC').where(option_type: 'option') }, class_name: 'FormFieldOption', dependent: :destroy, inverse_of: :form_field, foreign_key: :form_field_id
  has_many :statements, ->{ order('form_field_options.ordering ASC').where(option_type: 'statement') }, class_name: 'FormFieldOption', dependent: :destroy, inverse_of: :form_field, foreign_key: :form_field_id
  belongs_to :kpi
  accepts_nested_attributes_for :options, allow_destroy: true
  accepts_nested_attributes_for :statements, allow_destroy: true

  serialize :settings

  validates :fieldable_id, presence: true, numericality: true
  validates :fieldable_type, presence: true
  validates :name, presence: true
  validates :type, presence: true,
    format: { with: /\AFormField::/ }
  validates :ordering, presence: true, numericality: true

  validate :valid_range_settings?

  validates :kpi_id,
    uniqueness: { scope: [:fieldable_id, :fieldable_type], allow_blank: true, allow_nil: true }

  scope :for_events_in_company, ->(companies) { joins(
      'INNER JOIN campaigns ON campaigns.id=form_fields.fieldable_id AND
      form_fields.fieldable_type=\'Campaign\''
    ).where(campaigns: {company_id: companies})
  }

  def field_options(result)
    {as: :string}
  end

  def field_classes
    ['input-xlarge'] + (is_numeric? ? ['number'] : [])
  end

  def field_data
    {}
  end

  def store_value(value)
    value
  end

  def format_html(result)
    result.value
  end

  def format_csv(result)
    result.value
  end

  def css_class
    self.class.name.underscore.gsub('/', '_')
  end

  def is_hashed_value?
    false
  end

  def is_numeric?
    false
  end

  def is_attachable?
    false
  end

  # Returns true if the field can have options associated
  def is_optionable?
    false
  end

  def type_name
    self.class.name
  end

  def validate_result(result)
    if required? && (result.value.nil? || (result.value.is_a?(String) && result.value.empty?))
      result.errors.add(:value, I18n.translate('errors.messages.blank'))
    end
    if is_hashed_value?
      if required? && (result.value.nil? || (result.value.is_a?(Hash) && result.value.empty?))
        result.errors.add(:value, I18n.translate('errors.messages.blank'))
      elsif result.value.present?
        if result.value.is_a?(Hash)
          if result.value.any?{|k, v| v != '' && !is_valid_value_for_key?(k, v) }
            result.errors.add :value, :invalid
          elsif (result.value.keys.map(&:to_i) - valid_hash_keys).any?
            result.errors.add :value, :invalid  # If a invalid key was given
          end
        else
          result.errors.add :value, :invalid
        end
      end
    end

    if has_range_value_settings? && result.value.present? && !result.value.to_s.empty?
      val = result.value.to_s.strip
      if self.settings['range_format'] == 'characters'
        items = val.length
      elsif self.settings['range_format'] == 'words'
        items = val.scan(/\w+/).size
      elsif self.settings['range_format'] == 'digits'
        items = val.gsub(/[\.\,\s]/, '').length
      elsif self.settings['range_format'] == 'value'
        items = val.to_f rescue 0
      end

      min_result = !self.settings['range_min'].present? || (items >= self.settings['range_min'].to_i)
      max_result = !self.settings['range_max'].present? || (items <= self.settings['range_max'].to_i)

      if !min_result || !max_result
        result.errors.add :value, :invalid
      end
    end
  end

  def options_for_input
    if kpi_id.present?
      kpi.kpis_segments.map{|s| [s.text, s.id]}
    else
      self.options.order(:ordering).map{|o| [o.name, o.id]}
    end
  end

  # Allow to create new form fields from the report builder. Rails doesn't like mass-assignment of
  # the "type" attribute, so, after a basic validation, we assign this only for new fields
  def field_type=(type)
    self.type = type if new_record?
  end

  def min_options_allowed
    MIN_OPTIONS_ALLOWED
  end

  def min_statements_allowed
    MIN_STATEMENTS_ALLOWED
  end

  def value_is_numeric?(value)
    true if Float(value) rescue false
  end

  protected
    def valid_hash_keys
      options_for_input.map{|o| o[1]}
    end

    def is_valid_value_for_key?(key, value)
      value_is_numeric?(value)
    end

    def has_range_value_settings?
      self.settings &&
      self.settings.has_key?('range_format') && self.settings['range_format'] &&
      (
        (self.settings.has_key?('range_min') && self.settings['range_min'].present?) ||
        (self.settings.has_key?('range_max') && self.settings['range_max'].present?)
      )
    end

    def valid_range_settings?
      if self.settings
        errors.add :settings, :invalid if settings['range_format'] && !VALID_RANGE_FORMATS.include?(settings['range_format'])
        errors.add :settings, :invalid if settings['range_max'].present? && !value_is_numeric?(settings['range_max'])
        errors.add :settings, :invalid if settings['range_min'].present? && !value_is_numeric?(settings['range_min'])
        if settings['range_min'].present? &&  settings['range_max'].present? &&
          value_is_numeric?(settings['range_min']) && value_is_numeric?(settings['range_max']) &&
          settings['range_min'].to_i > settings['range_max'].to_i
          !value_is_numeric?(settings['range_min'])
          errors.add :settings, :invalid
        end
      end
    end
end
