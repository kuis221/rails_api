# == Schema Information
#
# Table name: brand_portfolios
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  active        :boolean          default(TRUE)
#  company_id    :integer
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  description   :text
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :brand_portfolio do
    sequence(:name) {|n| "Test Brand Portfolio #{n}" }
    description "Brand Portfolio Description"
    active true
    company_id 1
    created_by_id 1
    updated_by_id 1
  end
end
