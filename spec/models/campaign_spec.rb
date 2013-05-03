# == Schema Information
#
# Table name: campaigns
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  aasm_state    :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  company_id    :integer
#

require 'spec_helper'

describe Campaign do
  it { should validate_presence_of(:name) }

  it { should allow_mass_assignment_of(:name) }
  it { should allow_mass_assignment_of(:description) }

  describe "Get first and last events for a campaign" do
    describe "#first_event" do
      before(:each) do
        @campaign = FactoryGirl.create(:campaign)
        @first_event = FactoryGirl.create(:event, campaign_id: @campaign.id, start_date: '05/02/2019', start_time: '10:00am', end_date: '05/02/2019', end_time: '06:00pm', company_id: 1)
        @second_event = FactoryGirl.create(:event, campaign_id: @campaign.id, start_date: '05/03/2019', start_time: '08:00am', end_date: '05/03/2019', end_time: '12:00pm', company_id: 1)
        @third_event = FactoryGirl.create(:event, campaign_id: @campaign.id, start_date: '05/04/2019', start_time: '01:00pm', end_date: '05/04/2019', end_time: '03:00pm', company_id: 1)
      end

      it "should return the first event related to the campaign" do
        @campaign.first_event.should == @first_event
      end

      it "should return the last event related to the campaign" do
        @campaign.last_event.should == @third_event
      end
    end
  end

end
