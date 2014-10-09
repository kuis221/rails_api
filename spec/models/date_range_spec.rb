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

require 'rails_helper'

describe DateRange, type: :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to have_many(:date_items) }

  it { is_expected.to validate_presence_of(:name) }

  describe '#deactivate!' do
    it 'should deactivate the date range' do
      date_range = create(:date_range, active: true)
      expect(date_range.active).to be_truthy
      date_range.deactivate!
      expect(date_range.reload.active).to be_falsey
    end
  end

  describe '#activate!' do
    it 'should activate the date range' do
      date_range = create(:date_range, active: true)
      expect(date_range.active).to be_truthy
      date_range.deactivate!
      expect(date_range.reload.active).to be_falsey
    end
  end

end
