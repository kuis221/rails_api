# == Schema Information
#
# Table name: activities
#
#  id               :integer          not null, primary key
#  activity_type_id :integer
#  activitable_id   :integer
#  activitable_type :string(255)
#  campaign_id      :integer
#  active           :boolean          default(TRUE)
#  company_user_id  :integer
#  activity_date    :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

require 'spec_helper'

describe Activity do
  it { should belong_to(:activity_type) }
  it { should belong_to(:activitable) }
  it { should belong_to(:company_user) }

  it { should validate_presence_of(:activity_type_id) }
  it { should validate_presence_of(:company_user_id) }
  it { should validate_presence_of(:activity_date) }
  it { should validate_numericality_of(:activity_type_id) }
  it { should validate_numericality_of(:company_user_id) }

  describe "#activate" do
    let(:activity) { FactoryGirl.build(:activity, active: false) }

    it "should return the active value as true" do
      activity.activate!
      activity.reload
      activity.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:activity) { FactoryGirl.build(:activity, active: false) }

    it "should return the active value as false" do
      activity.deactivate!
      activity.reload
      activity.active.should be_false
    end
  end

  describe "with_results_for" do
    let(:activity_type) { FactoryGirl.create(:activity_type, company: campaign.company) }
    let(:field) { FactoryGirl.create(:form_field, type: 'FormField::TextArea', fieldable: activity_type ) }
    let(:venue) { FactoryGirl.create(:venue, company: campaign.company) }
    let(:campaign) { FactoryGirl.create(:campaign) }

    before { campaign.activity_types << activity_type }

    it "results empty if no activities have the give fields" do
      FactoryGirl.create(:activity, activity_type: activity_type,
        activitable: venue, campaign: campaign, company_user_id: 1)
      expect(Activity.with_results_for(field)).to be_empty
    end

    it "results the activity if have result for the field" do
      activity = FactoryGirl.create(:activity, activity_type: activity_type,
        activitable: venue, campaign: campaign, company_user_id: 1)
      activity.results_for([field]).first.value = 'this have a value'
      activity.save

      expect(Activity.with_results_for(field)).to match_array [activity]
    end

    it "should return each activity only once" do
      activity = FactoryGirl.create(:activity, activity_type: activity_type,
        activitable: venue, campaign: campaign, company_user_id: 1)

      field2 = FactoryGirl.create(:form_field, type: 'FormField::TextArea', fieldable: activity_type )
      activity.results_for([field, field2]).each{|r| r.value = 'this have a value' }
      expect {
        activity.save
      }.to change(ActivityResult, :count).by(2)

      expect(Activity.with_results_for([field, field2])).to match_array [activity]
    end
  end
end
