# == Schema Information
#
# Table name: day_items
#
#  id          :integer          not null, primary key
#  day_part_id :integer
#  start_time  :string(255)
#  end_time    :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'spec_helper'

describe DayItem, :type => :model do
  it { is_expected.to belong_to(:day_part)}
  it { is_expected.to validate_presence_of(:day_part_id)}
  it { is_expected.to validate_presence_of(:start_time)}

  describe "#label" do
    it "returns a valid description when has start_time and end_time" do
      time = DayItem.new(start_time: '6:00 AM', end_time: '2:00 PM')
      expect(time.label).to eq('From  6:00 AM to  2:00 PM')
    end

    it "returns a valid description when only have a start_time" do
      time = DayItem.new(start_time: '8:00 AM')
      expect(time.label).to eq('At  8:00 AM')
    end
  end
end
