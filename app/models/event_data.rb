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
#  cost                      :decimal(10, 2)   default(0.0)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#

class EventData < ActiveRecord::Base
  belongs_to :event
  attr_accessible :cost, :ethnicity_asian, :ethnicity_black, :ethnicity_hispanic, :ethnicity_native_american, :ethnicity_white, :gender_female, :gender_male, :impressions, :interactions, :samples

  def update_data
    results = EventResult.scoped_by_event_id(event_id)
    self.impressions = results.impressions.sum(:scalar_value).round
    self.interactions = results.consumers_interactions.sum(:scalar_value).round
    self.samples = results.consumers_sampled.sum(:scalar_value).round
    self.cost = results.spent.sum(:scalar_value).round

    #For gender and ethnicity
    segments_names_map = {
     gender: {'Male' => 'male', 'Female' => 'female'},
     ethnicity: {'Asian' => 'asian', 'Black / African American' => 'black', 'Hispanic / Latino' => 'hispanic', 'Native American' => 'native_american', 'White' => 'white'},
    }
    [:gender, :ethnicity].each do |kpi|
      segments = Kpi.send(kpi).kpis_segments
      segments.each{|s| self.send("#{kpi}_#{segments_names_map[kpi][s.text]}=", results.detect{|r| r.kpis_segment_id == s.id}.try(:scalar_value))}
    end

    save
  end
end