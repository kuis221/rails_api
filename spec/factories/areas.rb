# == Schema Information
#
# Table name: areas
#
#  id                            :integer          not null, primary key
#  name                          :string(255)
#  description                   :text
#  active                        :boolean          default(TRUE)
#  company_id                    :integer
#  created_by_id                 :integer
#  updated_by_id                 :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  common_denominators           :text
#  common_denominators_locations :integer          default([]), is an Array
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :area do
    sequence(:name) { |n| "Area #{n}" }
    description 'Area description'
    active true
    created_by_id 1
    updated_by_id 1
    company_id 1
  end
end
