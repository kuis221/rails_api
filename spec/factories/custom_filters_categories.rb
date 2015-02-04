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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :custom_filters_category do
    name "My Filters"
    company_id nil
  end
end
