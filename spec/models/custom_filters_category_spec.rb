# == Schema Information
#
# Table name: custom_filters_categories
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime
#  updated_at :datetime
#  company_id   :integer
#

require 'rails_helper'

describe CustomFiltersCategory, type: :model do
  it { is_expected.to belong_to(:company) }
  it { is_expected.to validate_presence_of(:name) }

  describe '#create' do
    it 'should include only custom filters category' do
      company = create(:company)
      create(:custom_filters_category, company: company, name: 'Custom Filter Category 1')
      custom_filters_category = CustomFiltersCategory.last
      expect(custom_filters_category.company).to eq(company)
      expect(custom_filters_category.name).to eq('Custom Filter Category 1')
    end
  end
end

