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
end
