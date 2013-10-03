# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  company_id  :integer
#  active      :boolean          default(TRUE)
#  description :text
#  is_admin    :boolean          default(FALSE)
#

require 'spec_helper'

describe Role do
  it { should belong_to(:company) }

  it { should validate_presence_of(:name) }

  it { should have_many(:company_users) }

  describe "#activate" do
    let(:role) { FactoryGirl.build(:role, active: false) }

    it "should return the active value as true" do
      role.activate!
      role.reload
      role.active.should be_true
    end
  end

  describe "#deactivate" do
    let(:role) { FactoryGirl.build(:role, active: false) }

    it "should return the active value as false" do
      role.deactivate!
      role.reload
      role.active.should be_false
    end
  end
end
