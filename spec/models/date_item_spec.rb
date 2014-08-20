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

require 'rails_helper'

describe DateItem, :type => :model do
  it { is_expected.to belong_to(:date_range)}
  it { is_expected.to validate_presence_of(:date_range_id)}
  it { is_expected.to validate_numericality_of(:date_range_id) }
  it { is_expected.to ensure_inclusion_of(:recurrence_type).in_array(['daily', 'weekly', 'monthly', 'yearly'])}
  it { is_expected.not_to allow_value(['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'hello']).for(:recurrence_days)}
  it { is_expected.to allow_value(['sunday', 'monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday']).for(:recurrence_days)}
  it { is_expected.to allow_value(nil).for(:recurrence_days)}
  it { is_expected.to allow_value(['']).for(:recurrence_days)}


  describe "end_after_start validation" do
    subject { DateItem.new(start_date: '01/22/2013') }

    it { is_expected.not_to allow_value('01/21/2013').for(:end_date).with_message("must be after") }
    it { is_expected.to allow_value('01/22/2013').for(:end_date) }
    it { is_expected.to allow_value('01/23/2013').for(:end_date) }
  end

  describe "#label" do
    it "returns a valid description when has start_date and end_date" do
      date = DateItem.new(start_date: '01/01/2013', end_date: '01/31/2013')
      expect(date.label).to eq('From 01/01/2013 to 01/31/2013')
    end

    it "returns a valid description when only have a start_date" do
      date = DateItem.new(start_date: '01/01/2013')
      expect(date.label).to eq('On 01/01/2013')
    end

    describe "with recurrence" do
      describe "with period of 1" do
        it "correctly describes the type for " do
          date = DateItem.new(recurrence: true, recurrence_period: 1, recurrence_type: 'daily')
          expect(date.label).to eq('Every day')
        end
        it "correctly describes the type for weekly" do
          date = DateItem.new(recurrence: true, recurrence_period: 1, recurrence_type: 'weekly')
          expect(date.label).to eq('Every week')
        end
        it "correctly describes the type for monthly" do
          date = DateItem.new(recurrence: true, recurrence_period: 1, recurrence_type: 'monthly')
          expect(date.label).to eq('Every month')
        end
        it "correctly describes the type for yearly" do
          date = DateItem.new(recurrence: true, recurrence_period: 1, recurrence_type: 'monthly')
          expect(date.label).to eq('Every month')
        end
      end
      describe "with period more than one" do
        it "correctly describes the type for " do
          date = DateItem.new(recurrence: true, recurrence_period: 3, recurrence_type: 'daily')
          expect(date.label).to eq('Every 3 days')
        end
        it "correctly describes the type for weekly" do
          date = DateItem.new(recurrence: true, recurrence_period: 3, recurrence_type: 'weekly')
          expect(date.label).to eq('Every 3 weeks')
        end
        it "correctly describes the type for monthly" do
          date = DateItem.new(recurrence: true, recurrence_period: 3, recurrence_type: 'monthly')
          expect(date.label).to eq('Every 3 months')
        end
        it "correctly describes the type for yearly" do
          date = DateItem.new(recurrence: true, recurrence_period: 3, recurrence_type: 'monthly')
          expect(date.label).to eq('Every 3 months')
        end
      end

      describe "with recurrence days" do
        it "correctly adds the day to the description" do
          date = DateItem.new(recurrence: true, recurrence_days: ['monday'])
          expect(date.label).to eq('On Monday')
        end
        it "correctly adds the days separated by 'AND'" do
          date = DateItem.new(recurrence: true, recurrence_days: ['monday', 'tuesday'])
          expect(date.label).to eq('On Monday and Tuesday')
        end
        it "correctly adds the days separated by commma and 'AND'" do
          date = DateItem.new(recurrence: true, recurrence_days: ['monday', 'tuesday', 'wednesday'])
          expect(date.label).to eq('On Monday, Tuesday, and Wednesday')
        end
        it "should ignore empty days" do
          date = DateItem.new(recurrence: true, recurrence_days: [''])
          expect(date.label).to eq('')
        end
      end

      describe "with period and recurrence days" do
        it "describe it correcly" do
          date = DateItem.new(recurrence: true, recurrence_type: 'daily', recurrence_period: '3',  recurrence_days: ['monday'])
          expect(date.label).to eq('Every 3 days on Monday')
        end
      end

      describe "with dates, period and recurrence days" do
        it "describe it correcly" do
          date = DateItem.new(recurrence: true, start_date: '01/31/2013', end_date: '02/24/2013', recurrence_type: 'weekly', recurrence_period: '3',  recurrence_days: ['monday'])
          expect(date.label).to eq('From 01/31/2013 to 02/24/2013 every 3 weeks on Monday')
        end
      end


    end
  end
end

