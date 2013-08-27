# == Schema Information
#
# Table name: date_ranges
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

describe DateRange do
  it { should belong_to(:company) }
  it { should have_many(:date_items) }

  it { should validate_presence_of(:name) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:description) }
  it { should_not allow_mass_assignment_of(:id) }
  it { should_not allow_mass_assignment_of(:company_id) }
  it { should_not allow_mass_assignment_of(:created_by_id) }
  it { should_not allow_mass_assignment_of(:updated_by_id) }
  it { should_not allow_mass_assignment_of(:created_at) }
  it { should_not allow_mass_assignment_of(:updated_at) }

  describe '#deactivate!' do
    it "should deactivate the date range" do
      date_range = FactoryGirl.create(:date_range, active: true)
      date_range.active.should be_true
      date_range.deactivate!
      date_range.reload.active.should be_false
    end
  end

  describe '#activate!' do
    it "should activate the date range" do
      date_range = FactoryGirl.create(:date_range, active: true)
      date_range.active.should be_true
      date_range.deactivate!
      date_range.reload.active.should be_false
    end
  end

end
