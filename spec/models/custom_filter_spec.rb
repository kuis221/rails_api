# == Schema Information
#
# Table name: custom_filters
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  apply_to   :string(255)
#  filters    :text
#  created_at :datetime
#  updated_at :datetime
#  owner_id   :integer
#  owner_type :string(255)
#  group      :string(255)
#

require 'rails_helper'

describe CustomFilter, type: :model do
  it { is_expected.to belong_to(:owner) }
  it { is_expected.to validate_presence_of(:owner) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:group) }
  it { is_expected.to validate_presence_of(:apply_to) }
  it { is_expected.to validate_presence_of(:filters) }

  describe '#by_type' do
    it 'should include only custom filters for events' do
      owner = create(:company_user)
      cf1 = create(:custom_filter, owner: owner, name: 'Custom Filter 1', apply_to: 'events')
      cf2 = create(:custom_filter, owner: owner, name: 'Custom Filter 2', apply_to: 'teams')
      cf3 = create(:custom_filter, owner: owner, name: 'Custom Filter 3', apply_to: 'brands')
      cf4 = create(:custom_filter, owner: owner, name: 'Custom Filter 4', apply_to: 'events')

      expect(CustomFilter.by_type('events')).to match_array [cf1, cf4]
    end
  end
end
