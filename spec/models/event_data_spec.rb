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

require 'rails_helper'

describe EventData, :type => :model do
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
      expect(event.event_data.impressions).to  eq(0)
      expect(event.event_data.interactions).to eq(0)
      expect(event.event_data.samples).to      eq(0)

      expect(event.event_data.spent).to eq(0)

      expect(event.event_data.gender_female).to eq(0.0)
      expect(event.event_data.gender_male).to eq(0.0)

      expect(event.event_data.ethnicity_asian).to   eq(0.0)
      expect(event.event_data.ethnicity_black).to   eq(0.0)
      expect(event.event_data.ethnicity_hispanic).to eq(0.0)
      expect(event.event_data.ethnicity_native_american).to eq(0.0)
      expect(event.event_data.ethnicity_white).to eq(0.0)
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
      expect(event.event_data.impressions).to  eq(101)
      expect(event.event_data.interactions).to eq(102)
      expect(event.event_data.samples).to      eq(103)

      expect(event.event_data.spent).to      eq(345)

      expect(event.event_data.gender_female).to  eq(70)
      expect(event.event_data.gender_male).to    eq(30)

      expect(event.event_data.ethnicity_asian).to    eq(30)
      expect(event.event_data.ethnicity_black).to    eq(20)
      expect(event.event_data.ethnicity_hispanic).to    eq(5)
      expect(event.event_data.ethnicity_native_american).to    eq(35)
      expect(event.event_data.ethnicity_white).to    eq(10)
    end
  end
end
