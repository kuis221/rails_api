# == Schema Information
#
# Table name: custom_filters_categories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  company_id :integer
#  created_at :datetime
#  updated_at :datetime
#

require 'rails_helper'

describe CustomFiltersCategory, type: :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to validate_presence_of(:name) }

  describe '#create' do
    it 'should include only custom filters category' do
      company = create(:company)
      create(:custom_filters_category, company: company, name: 'Custom Filter Category 1')
      custom_filters_category = described_class.last
      expect(custom_filters_category.company).to eq(company)
      expect(custom_filters_category.name).to eq('Custom Filter Category 1')
    end
  end
end
