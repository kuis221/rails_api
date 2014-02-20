# == Schema Information
#
# Table name: event_results
#
#  id              :integer          not null, primary key
#  form_field_id   :integer
#  event_id        :integer
#  kpis_segment_id :integer
#  value           :text
#  scalar_value    :decimal(10, 2)   default(0.0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  kpi_id          :integer
#

class EventResult < ActiveRecord::Base
	belongs_to :event
  belongs_to :kpis_segment
	belongs_to :kpi
	belongs_to :form_field, class_name: 'CampaignFormField'

  attr_accessible :form_field_id, :kpis_segment_id, :kpi_id, :value

  before_save :set_scalar_value
  before_validation :clean_up_invalid_values

  validate :valid_value?

  validates :value, numericality: true, allow_nil: true, allow_blank: true, if: :allow_decimals?
  validates :value, numericality: { only_integer: true }, allow_nil: true, allow_blank: true, if: :is_numeric_field?, unless: :allow_decimals?
  validates :form_field_id, numericality: true, presence: true
  validates :kpi_id, numericality: true, allow_nil: true
  validates :kpis_segment_id, numericality: true, allow_nil: true
  validates :scalar_value, numericality: true, allow_nil: true, allow_blank: true

  scope :scoped_by_company_id, lambda{|companies| joins(:event).where(events: {company_id: companies}) }
  scope :for_approved_events, lambda{ joins(:event).where(events: {aasm_state: 'approved'}) }
  scope :for_active_events, lambda{ joins(:event).where(events: {active: true}) }
  scope :scoped_by_place_id_and_company_id, lambda{|places, companies| joins(:event).where(events: {place_id: places, company_id: companies}) }
  scope :scoped_by_campaign_id, lambda{|campaigns| joins(:form_field).where(campaign_form_fields: {campaign_id: campaigns}) }
  scope :impressions, lambda{ where(kpi_id: Kpi.impressions) }
  scope :consumers_interactions, lambda{ where(kpi_id: Kpi.interactions) }
  scope :consumers_sampled, lambda{ where(kpi_id: Kpi.samples) }
  scope :spent, lambda{ where(kpi_id: Kpi.expenses) }
  scope :gender, lambda{ where(kpis_segment_id: Kpi.gender.kpis_segment_ids) }
  scope :age, lambda{ where(kpis_segment_id: Kpi.age.kpis_segment_ids) }
  scope :ethnicity, lambda{ where(kpis_segment_id: Kpi.ethnicity.kpis_segment_ids) }

  delegate :is_numeric?, :capture_mechanism, to: :form_field, allow_nil: true

  def display_value
    if form_field.field_type == 'count'
      if capture_mechanism == 'checkbox'
        form_field.kpi.kpis_segments.select{|s| self.value.include?(s.id)}.map(&:text).to_sentence if self.value
      else
        form_field.kpi.kpis_segments.detect{|s| s.id == self.value}.try(:text) if self.value
      end
    else
      self.value
    end
  end

  def value
    if form_field.present? && form_field.field_type == 'count' && capture_mechanism == 'checkbox'
      if self.attributes['value'].is_a?(String)
        self.attributes['value'].try(:split, ',').try(:map , &:to_i)
      elsif self.attributes['value'].is_a?(Numeric)
        [self.attributes['value']]
      else
        self.attributes['value']
      end
    elsif form_field.present? && form_field.is_numeric? && !form_field.is_decimal? && self.attributes['value'].present? && self.attributes['value'] != '' && self.attributes['value'].respond_to?(:to_i)
      self.attributes['value'].to_i
    else
      self.attributes['value']
    end
  end

  def value=(value)
    if form_field.field_type == 'count' && capture_mechanism == 'checkbox' && value.is_a?(Array)
      write_attribute('value', value.map{|v| v.is_a?(String) ? v.strip : v}.join(','))
    else
      write_attribute('value', value)
    end
  end

  private
    def set_scalar_value
      if value.present? and is_numeric?
        self.scalar_value = value.to_f rescue 0
      else
        self.scalar_value = 0
      end
    end

    def clean_up_invalid_values
      self.value = nil if (self.value == 0 || self.value == '0') && form_field.field_type == 'count'
    end

    def is_numeric_field?
      form_field.present? && ['percentage', 'number'].include?(form_field.field_type)
    end

    def allow_decimals?
      is_numeric_field? && ['currency', 'decimal'].include?(capture_mechanism)
    end

    def valid_value?
      return if form_field.nil?
      if form_field.is_required? && (value.nil? || (value.is_a?(String) && value.empty?))
        errors.add(:value, I18n.translate('errors.messages.blank'))
      end

      if form_field.field_type == 'count' && value.present? && value != '' && value != '0'
        if value.present? && capture_mechanism == 'radio' && (!value.is_a?(Integer) || !form_field.kpi.kpis_segment_ids.include?(value))
          errors.add(:value, I18n.translate('errors.result.invalid'))
        end

        if value.present? && capture_mechanism == 'checkbox' && value.any?{|v| !form_field.kpi.kpis_segment_ids.include?(v) }
          errors.add(:value, I18n.translate('errors.result.invalid'))
        end

        if capture_mechanism != 'checkbox'
          errors.add(:value, I18n.translate('errors.messages.not_a_number')) if !parse_raw_value_as_a_number(value)
        else capture_mechanism == 'checkbox'
          errors.add(:value, I18n.translate('errors.messages.not_a_number')) if value.any?{|v| !parse_raw_value_as_a_number(v)}
        end
      end
    end

    def parse_raw_value_as_a_number(raw_value)
      Kernel.Float(raw_value) if raw_value !~ /\A0[xX]/
    rescue ArgumentError, TypeError
      nil
    end
end
