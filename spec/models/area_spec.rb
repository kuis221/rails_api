# == Schema Information
#
# Table name: areas
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

require 'spec_helper'

describe Area do
  it { should belong_to(:company) }

  it { should validate_presence_of(:name) }


  describe "#activate" do
    let(:area) { FactoryGirl.build(:area, active: false) }

    it "should return the active value as true" do
      area.activate!
      area.reload
      area.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:area) { FactoryGirl.build(:area, active: false) }

    it "should return the active value as false" do
      area.deactivate!
      area.reload
      area.active.should be_false
    end
  end
end
