# == Schema Information
#
# Table name: day_parts
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  active        :boolean          default(TRUE)
#  company_id    :integer
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

require 'rails_helper'

describe DayPart, :type => :model do
  it { is_expected.to belong_to(:company) }

  it { is_expected.to validate_presence_of(:name) }

  describe "#activate" do
    let(:day_part) { FactoryGirl.build(:day_part, active: false) }

    it "should return the active value as true" do
      day_part.activate!
      day_part.reload
      expect(day_part.active).to be_truthy
    end
  end

  describe "#deactivate" do
    let(:day_part) { FactoryGirl.build(:day_part, active: false) }

    it "should return the active value as false" do
      day_part.deactivate!
      day_part.reload
      expect(day_part.active).to be_falsey
    end
  end
end
