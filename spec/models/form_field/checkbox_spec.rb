# == Schema Information
#
# Table name: form_fields
#
#  id             :integer          not null, primary key
#  fieldable_id   :integer
#  fieldable_type :string(255)
#  name           :string(255)
#  type           :string(255)
#  settings       :text
#  ordering       :integer
#  required       :boolean
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  kpi_id         :integer
#  multiple       :boolean
#

require 'rails_helper'

describe FormField::Checkbox, type: :model do
  let(:company) { create(:company) }
  let(:activity_type) { create(:activity_type, company: company) }
  let(:field) { create(:form_field_checkbox, options: [], fieldable: activity_type) }

  before { Company.current = company }

  describe '#value' do
    let(:brand) { create(:brand) }
    let(:campaign) { create(:campaign, brand_ids: [brand.id], company: company) }
    let(:venue) { create(:venue, place: create(:place), company: company) }
    let(:activity) { create(:activity, activity_type: activity_type, activitable: venue, campaign: campaign, company_user_id: 1) }

    before {
      campaign.activity_types << activity_type
    }

    it 'should return the correct values' do
      ff_result = create(:form_field_result, resultable: activity, form_field: field, value: nil, hash_value: nil)
      expect(ff_result.value).to eql []

      ff_result.update_attribute(:value, '')
      expect(ff_result.value).to eql []

      ff_result.update_attribute(:hash_value, '"925"=>"1"')
      expect(ff_result.value).to eql [925]

      ff_result.update_attribute(:hash_value, '"925"=>"1", "926"=>"1"')
      expect(ff_result.value).to eql [925, 926]
    end
  end

end
