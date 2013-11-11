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
	belongs_to :form_field, class_name: 'CampaignFormField'

  attr_accessible :form_field_id, :kpis_segment_id, :kpi_id, :value

  before_save :set_scalar_value

  validate :valid_value?

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

  def display_value
    if form_field.field_type == 'count'
      if form_field.capture_mechanism == 'checkbox'
        form_field.kpi.kpis_segments.where(id: self.value).map(&:text).to_sentence if self.value
      else
        form_field.kpi.kpis_segments.where(id: self.value).first.try(:text) if self.value
      end
    else
      self.value
    end
  end

  def value
    if form_field.field_type == 'count' && form_field.capture_mechanism == 'checkbox'
      self.attributes['value'].try(:split, ',').try(:map , &:to_i)
    else
      self.attributes['value']
    end
  end

  def value=(value)
    if form_field.field_type == 'count' && form_field.capture_mechanism == 'checkbox' && value.is_a?(Array)
      write_attribute('value', value.reject{|v| !(v =~ /^[0-9]+$/) }.join(','))
    else
      write_attribute('value', value)
    end
  end

  private
    def set_scalar_value
      if value.present? and form_field.is_numeric?
        self.scalar_value = value.to_f rescue 0
      else
        self.scalar_value = 0
      end
    end

    def valid_value?
      return if form_field.nil?
      if form_field.is_required? && (value.nil? || (value.is_a?(String) && value.empty?))
        errors.add(:value, I18n.translate('errors.messages.blank'))
      end
    end
end
