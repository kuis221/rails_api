# == Schema Information
#
# Table name: event_data
#
#  id                        :integer          not null, primary key
#  event_id                  :integer
#  impressions               :integer          default(0)
#  interactions              :integer          default(0)
#  samples                   :integer          default(0)
#  gender_female             :decimal(5, 2)    default(0.0)
#  gender_male               :decimal(5, 2)    default(0.0)
#  ethnicity_asian           :decimal(5, 2)    default(0.0)
#  ethnicity_black           :decimal(5, 2)    default(0.0)
#  ethnicity_hispanic        :decimal(5, 2)    default(0.0)
#  ethnicity_native_american :decimal(5, 2)    default(0.0)
#  ethnicity_white           :decimal(5, 2)    default(0.0)
#  cost                      :decimal(10, 2)   default(0.0)
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#

require 'spec_helper'

describe EventData do
  before do
    ResqueSpec.reset!
  end
  let(:event) { FactoryGirl.create(:event) }
  describe "#update_data" do
    it "should queue a job for updating venue data" do
      expect {
        event.event_data.update_data
      }.to change(Venue, :count).by(1)
      #Venue.should have_queued(person.id, :calculate)
    end
  end
end
