# == Schema Information
#
# Table name: campaign_form_fields
#
#  id          :integer          not null, primary key
#  campaign_id :integer
#  kpi_id      :integer
#  ordering    :integer
#  name        :string(255)
#  field_type  :string(255)
#  options     :text
#  section_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

FactoryGirl.define do
  factory :campaign_form_field do
    campaign nil
    kpi nil
    ordering 1
    name "MyString"
    field_type "number"
    options {}
    section_id nil
  end
end
