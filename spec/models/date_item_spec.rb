# == Schema Information
#
# Table name: date_items
#
#  id                :integer          not null, primary key
#  date_range_id     :integer
#  start_date        :date
#  end_date          :date
#  recurrence        :boolean          default(FALSE)
#  recurrence_type   :string(255)
#  recurrence_period :integer
#  recurrence_days   :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'spec_helper'

describe DateItem do
  it { should belong_to(:date_range)}
  it { should validate_presence_of(:date_range_id)}
  it { should ensure_inclusion_of(:recurrence_type).in_array(['daily', 'weekly', 'monthly', 'yearly'])}
  it { should_not allow_value(['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'hello']).for(:recurrence_days)}
  it { should allow_value(['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']).for(:recurrence_days)}
  it { should allow_value(nil).for(:recurrence_days)}
  it { should allow_value(['']).for(:recurrence_days)}

  it { should allow_mass_assignment_of(:start_date)}
  it { should allow_mass_assignment_of(:end_date)}
  it { should allow_mass_assignment_of(:recurrence)}
  it { should allow_mass_assignment_of(:recurrence_type)}
  it { should allow_mass_assignment_of(:recurrence_period)}
  it { should allow_mass_assignment_of(:recurrence_days)}

  it { should_not allow_mass_assignment_of(:created_at)}
  it { should_not allow_mass_assignment_of(:updated_at)}

  describe "#label" do
    it "returns a valid description when has start_date and end_date" do
      date = DateItem.new(start_date: '01/01/2013', end_date: '01/31/2013')
      date.label.should == 'From 01/01/2013 to 01/31/2013'
    end

    it "returns a valid description when only have a start_date" do
      date = DateItem.new(start_date: '01/01/2013')
      date.label.should == 'On 01/01/2013'
    end

    describe "with recurrence" do
      describe "with period of 1" do
        it "correctly describes the type for " do
          date = DateItem.new(recurrence: true, recurrence_period: 1, recurrence_type: 'daily')
          date.label.should == 'Every day'
        end
        it "correctly describes the type for weekly" do
          date = DateItem.new(recurrence: true, recurrence_period: 1, recurrence_type: 'weekly')
          date.label.should == 'Every week'
        end
        it "correctly describes the type for monthly" do
          date = DateItem.new(recurrence: true, recurrence_period: 1, recurrence_type: 'monthly')
          date.label.should == 'Every month'
        end
        it "correctly describes the type for yearly" do
          date = DateItem.new(recurrence: true, recurrence_period: 1, recurrence_type: 'monthly')
          date.label.should == 'Every month'
        end
      end
      describe "with period more than one" do
        it "correctly describes the type for " do
          date = DateItem.new(recurrence: true, recurrence_period: 3, recurrence_type: 'daily')
          date.label.should == 'Every 3 days'
        end
        it "correctly describes the type for weekly" do
          date = DateItem.new(recurrence: true, recurrence_period: 3, recurrence_type: 'weekly')
          date.label.should == 'Every 3 weeks'
        end
        it "correctly describes the type for monthly" do
          date = DateItem.new(recurrence: true, recurrence_period: 3, recurrence_type: 'monthly')
          date.label.should == 'Every 3 months'
        end
        it "correctly describes the type for yearly" do
          date = DateItem.new(recurrence: true, recurrence_period: 3, recurrence_type: 'monthly')
          date.label.should == 'Every 3 months'
        end
      end

      describe "with recurrence days" do
        it "correctly adds the day to the description" do
          date = DateItem.new(recurrence: true, recurrence_days: ['monday'])
          date.label.should == 'On Monday'
        end
        it "correctly adds the days separated by 'AND'" do
          date = DateItem.new(recurrence: true, recurrence_days: ['monday', 'tuesday'])
          date.label.should == 'On Monday and Tuesday'
        end
        it "correctly adds the days separated by commma and 'AND'" do
          date = DateItem.new(recurrence: true, recurrence_days: ['monday', 'tuesday', 'wednesday'])
          date.label.should == 'On Monday, Tuesday and Wednesday'
        end
        it "should ignore empty days" do
          date = DateItem.new(recurrence: true, recurrence_days: [''])
          date.label.should == ''
        end
      end

      describe "with period and recurrence days" do
        it "describe it correcly" do
          date = DateItem.new(recurrence: true, recurrence_type: 'daily', recurrence_period: '3',  recurrence_days: ['monday'])
          date.label.should == 'Every 3 days on Monday'
        end
      end

      describe "with dates, period and recurrence days" do
        it "describe it correcly" do
          date = DateItem.new(recurrence: true, start_date: '01/31/2013', end_date: '02/24/2013', recurrence_type: 'weekly', recurrence_period: '3',  recurrence_days: ['monday'])
          date.label.should == 'From 01/31/2013 to 02/24/2013 every 3 weeks on Monday'
        end
      end


    end
  end
end

