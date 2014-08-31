# == Schema Information
#
# Table name: custom_filters
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  name            :string(255)
#  apply_to        :string(255)
#  filters         :text
#  created_at      :datetime
#  updated_at      :datetime
#

require 'rails_helper'

describe CustomFilter, :type => :model do
  it { is_expected.to belong_to(:company_user) }
  it { is_expected.to validate_presence_of(:company_user_id) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:apply_to) }
  it { is_expected.to validate_presence_of(:filters) }
  it { is_expected.to validate_numericality_of(:company_user_id) }

  describe "#by_type" do
    it "should include only custom filters for events" do
      cf1 = FactoryGirl.create(:custom_filter, company_user_id: 1, name: 'Custom Filter 1', apply_to: 'events')
      cf2 = FactoryGirl.create(:custom_filter, company_user_id: 1, name: 'Custom Filter 2', apply_to: 'teams')
      cf3 = FactoryGirl.create(:custom_filter, company_user_id: 1, name: 'Custom Filter 3', apply_to: 'brands')
      cf4 = FactoryGirl.create(:custom_filter, company_user_id: 1, name: 'Custom Filter 4', apply_to: 'events')

      expect(CustomFilter.by_type('events')).to match_array [cf1, cf4]
    end
  end
end
