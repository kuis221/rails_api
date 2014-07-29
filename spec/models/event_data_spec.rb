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

require 'spec_helper'

describe EventData do
  before do
    ResqueSpec.reset!
    Kpi.delete_all
  end

  let(:event) { FactoryGirl.create(:event, event_data: FactoryGirl.build(:event_data), campaign: FactoryGirl.create(:campaign)) }
  describe "#update_data" do
    it "should set values to 0 if the event has no data" do
      Kpi.create_global_kpis
      event.campaign.assign_all_global_kpis
      event.save

      # Call the method manually
      event.event_data.update_data

      event.event_data.update_data
      event.event_data.impressions.should  == 0
      event.event_data.interactions.should == 0
      event.event_data.samples.should      == 0

      event.event_data.spent.should == 0

      event.event_data.gender_female.should == 0.0
      event.event_data.gender_male.should == 0.0

      event.event_data.ethnicity_asian.should   ==  0.0
      event.event_data.ethnicity_black.should   ==  0.0
      event.event_data.ethnicity_hispanic.should == 0.0
      event.event_data.ethnicity_native_american.should == 0.0
      event.event_data.ethnicity_white.should == 0.0
    end

    it "should correctly count the values for each segment" do
      Kpi.create_global_kpis
      event.campaign.assign_all_global_kpis

      # Assign the values for the kpis
      event.result_for_kpi(Kpi.impressions).value = '101'
      event.result_for_kpi(Kpi.interactions).value = '102'
      event.result_for_kpi(Kpi.samples).value = '103'

      # Assign values for the gender
      gender_results = event.result_for_kpi(Kpi.gender)

      male_segment = Kpi.gender.kpis_segments.detect{|s| s.text == 'Male' }
      female_segment = Kpi.gender.kpis_segments.detect{|s| s.text == 'Female' }
      gender_results.value = {male_segment.id => '30',
                             female_segment.id => '70'}


      # Assign values for the ethnicity
      ethnicity_results = event.result_for_kpi(Kpi.ethnicity)

      segment1 = Kpi.ethnicity.kpis_segments.detect{|s| s.text == 'Asian' }
      segment2 = Kpi.ethnicity.kpis_segments.detect{|s| s.text == 'Black / African American' }
      segment3 = Kpi.ethnicity.kpis_segments.detect{|s| s.text == 'Hispanic / Latino' }
      segment4 = Kpi.ethnicity.kpis_segments.detect{|s| s.text == 'Native American' }
      segment5 = Kpi.ethnicity.kpis_segments.detect{|s| s.text == 'White' }
      ethnicity_results.value = {segment1.id => '30',
                                 segment2.id => '20',
                                 segment3.id => '5',
                                 segment4.id => '35',
                                 segment5.id => '10'}

      event.save

      event.event_expenses.create(name: 'test expense', amount: 345)


      # Call the method manually
      event.event_data.update_data
      event.event_data.impressions.should  == 101
      event.event_data.interactions.should == 102
      event.event_data.samples.should      == 103

      event.event_data.spent.should      == 345

      event.event_data.gender_female.should  == 70
      event.event_data.gender_male.should    == 30

      event.event_data.ethnicity_asian.should    == 30
      event.event_data.ethnicity_black.should    == 20
      event.event_data.ethnicity_hispanic.should    == 5
      event.event_data.ethnicity_native_american.should    == 35
      event.event_data.ethnicity_white.should    == 10
    end
  end
end
