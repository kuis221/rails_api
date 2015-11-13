# == Schema Information
#
# Table name: custom_filters
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  apply_to     :string(255)
#  filters      :text
#  created_at   :datetime
#  updated_at   :datetime
#  owner_id     :integer
#  owner_type   :string(255)
#  default_view :boolean          default(FALSE)
#  category_id  :integer
#

require 'rails_helper'

describe CustomFilter, type: :model do
  it { is_expected.to belong_to(:owner) }
  it { is_expected.to validate_presence_of(:owner) }
  it { is_expected.to validate_presence_of(:name) }
  it { is_expected.to validate_presence_of(:apply_to) }
  it { is_expected.to validate_presence_of(:filters) }

  describe '#by_type' do
    it 'should include only custom filters for events' do
      owner = create(:company_user)
      cf1 = create(:custom_filter, owner: owner, name: 'Custom Filter 1', apply_to: 'events')
      cf2 = create(:custom_filter, owner: owner, name: 'Custom Filter 2', apply_to: 'teams')
      cf3 = create(:custom_filter, owner: owner, name: 'Custom Filter 3', apply_to: 'brands')
      cf4 = create(:custom_filter, owner: owner, name: 'Custom Filter 4', apply_to: 'events')

      expect(described_class.by_type('events')).to match_array [cf1, cf4]
    end
  end

  describe '#to_params' do
    let(:custom_filter_category) { create(:custom_filters_category, name: 'Fiscal Years', company: create(:company)) }
    let(:custom_user) { create(:company_user) }

    it 'should remove the invalid dates' do
      custom_filter = create(:custom_filter, owner: custom_user, name: 'My Dates Range', apply_to: 'events',
                      filters: 'status%5B%5D=Active&start_date=7%2F28%2F2013',
                      category: custom_filter_category)

      expect(custom_filter.to_params.to_query).to eq('status%5B%5D=Active')
    end

    it 'should remove the invalid length array dates' do
      custom_filter = create(:custom_filter, owner: custom_user, name: 'My Dates Range', apply_to: 'events',
                      filters: 'status%5B%5D=Active&start_date%5B%5D=7%2F28%2F2013&start_date%5B%5D=7%2F29%2F2013&end_date%5B%5D=7%2F28%2F2013',
                      category: custom_filter_category)

      expect(custom_filter.to_params.to_query).to eq('status%5B%5D=Active')
    end

    it 'should not remove the dates' do
      custom_filter = create(:custom_filter, owner: custom_user, name: 'My Dates Range', apply_to: 'events',
                      filters: 'status%5B%5D=Active&start_date=7%2F28%2F2013&end_date=7%2F28%2F2013',
                      category: custom_filter_category)

      expect(custom_filter.to_params.to_query).to eq('end_date=7%2F28%2F2013&start_date=7%2F28%2F2013&status%5B%5D=Active')
    end

    it 'should not remove the dates arrays' do
      custom_filter = create(:custom_filter, owner: custom_user, name: 'My Dates Range', apply_to: 'events',
                      filters: 'start_date%5B%5D=7%2F28%2F2013&start_date%5B%5D=7%2F29%2F2013&end_date%5B%5D=7%2F28%2F2013&end_date%5B%5D=7%2F29%2F2013',
                      category: custom_filter_category)

      expect(custom_filter.to_params.to_query).to eq('end_date%5B%5D=7%2F28%2F2013&end_date%5B%5D=7%2F29%2F2013&start_date%5B%5D=7%2F28%2F2013&start_date%5B%5D=7%2F29%2F2013')
    end
  end
end
