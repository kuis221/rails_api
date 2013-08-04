# == Schema Information
#
# Table name: venues
#
#  id              :integer          not null, primary key
#  company_id      :integer
#  place_id        :integer
#  events          :integer
#  promo_hours     :decimal(8, 2)    default(0.0)
#  impressions     :integer
#  interactions    :integer
#  sampled         :integer
#  spent           :decimal(10, 2)   default(0.0)
#  score           :integer
#  avg_impressions :decimal(8, 2)    default(0.0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'spec_helper'

describe Venue do
  it { should belong_to(:place) }
  it { should belong_to(:company) }

  describe "compute_stats" do
    let(:venue) { FactoryGirl.create(:venue, company_id: 1, place_id: 1) }

    it "return succeed if there are no events  for this venue" do
      venue.compute_stats.should be_true
    end

    it "count the number of events for the company" do
      venue.save
      e = FactoryGirl.create(:event, company_id: 1, place_id: 1, start_date: "01/23/2019", end_date: "01/23/2019", start_time: '8:00am', end_time: '11:00am')
      FactoryGirl.create(:event, company_id: 1, place_id: 2) # Create another event for other place
      FactoryGirl.create(:event, company_id: 2, place_id: 1) # Create another event for other company

      venue.compute_stats
      venue.reload
      venue.events.should == 1
      venue.promo_hours.to_i.should == 3

      # TODO: test the values for impressions, interactions and other kpis values
    end
  end
end
