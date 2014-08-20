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

require 'rails_helper'

describe Activity, :type => :model do
  it { is_expected.to belong_to(:activity_type) }
  it { is_expected.to belong_to(:activitable) }
  it { is_expected.to belong_to(:company_user) }

  it { is_expected.to validate_presence_of(:activity_type_id) }
  it { is_expected.to validate_presence_of(:company_user_id) }
  it { is_expected.to validate_presence_of(:activity_date) }
  it { is_expected.to validate_numericality_of(:activity_type_id) }
  it { is_expected.to validate_numericality_of(:company_user_id) }

  describe "#activate" do
    let(:activity) { FactoryGirl.build(:activity, active: false) }

    it "should return the active value as true" do
      activity.activate!
      activity.reload
      expect(activity.active).to be_truthy
    end
  end

  describe "#deactivate" do
    let(:activity) { FactoryGirl.build(:activity, active: false) }

    it "should return the active value as false" do
      activity.deactivate!
      activity.reload
      expect(activity.active).to be_falsey
    end
  end
end
