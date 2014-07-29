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

  describe '#deactivate!' do
    it "should deactivate the date range" do
      date_range = FactoryGirl.create(:date_range, active: true)
      date_range.active.should be_truthy
      date_range.deactivate!
      date_range.reload.active.should be_falsey
    end
  end

  describe '#activate!' do
    it "should activate the date range" do
      date_range = FactoryGirl.create(:date_range, active: true)
      date_range.active.should be_truthy
      date_range.deactivate!
      date_range.reload.active.should be_falsey
    end
  end

end
