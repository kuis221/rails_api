# == Schema Information
#
# Table name: event_data
#
#  id                        :integer          not null, primary key
#  event_id                  :integer
#  impressions               :integer          default(0)
#  interactions              :integer          default(0)
#  samples                   :integer          default(0)
#  gender_female             :decimal(5, 2)    default(0.0)
#  gender_male               :decimal(5, 2)    default(0.0)
#  ethnicity_asian           :decimal(5, 2)    default(0.0)
#  ethnicity_black           :decimal(5, 2)    default(0.0)
#  ethnicity_hispanic        :decimal(5, 2)    default(0.0)
#  ethnicity_native_american :decimal(5, 2)    default(0.0)
#  ethnicity_white           :decimal(5, 2)    default(0.0)
#  spent                     :decimal(10, 2)   default(0.0)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#

class EventData < ActiveRecord::Base
  SEGMENTS_NAMES_MAP = {
     gender:    {'Male' => 'male', 'Female' => 'female'},
     ethnicity: {'Asian' => 'asian', 'Black / African American' => 'black', 'Hispanic / Latino' => 'hispanic', 'Native American' => 'native_american', 'White' => 'white'}
  }

  belongs_to :event
  attr_accessible :spent, :ethnicity_asian, :ethnicity_black, :ethnicity_hispanic, :ethnicity_native_american, :ethnicity_white, :gender_female, :gender_male, :impressions, :interactions, :samples

  scope :scoped_by_place_id_and_company_id, lambda{|places, companies| joins(:event).where(events: {place_id: places, company_id: companies}) }

  scope :scoped_by_company_id, lambda{|companies| joins(:event).where(events: {company_id: companies}) }
  scope :scoped_by_campaign_id, lambda{|campaigns| joins(:event).where(events: {campaign_id: campaigns}) }
  scope :for_approved_events, lambda{ joins(:event).where(events: {aasm_state: 'approved'}) }
  scope :for_active_events, lambda{ joins(:event).where(events: {active: true}) }

  def update_data
    results = EventResult.scoped_by_event_id(event_id)
    self.impressions  = (results.impressions.first.try(:scalar_value) || 0).round
    self.interactions = (results.consumers_interactions.first.try(:scalar_value) || 0).round
    self.samples      = (results.consumers_sampled.first.try(:scalar_value) || 0).round
    self.spent = event.event_expenses.sum(:amount)

    #For gender and ethnicity
    [:gender, :ethnicity].each do |kpi|
      segments = Kpi.send(kpi).try(:kpis_segments)
      segments.each{|s| self.send("#{kpi}_#{SEGMENTS_NAMES_MAP[kpi][s.text]}=", results.detect{|r| r.kpis_segment_id == s.id}.try(:scalar_value))} if segments
    end

    self
  end
end
