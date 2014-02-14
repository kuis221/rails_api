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

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :date_range do
    sequence(:name) {|n| "Date Range #{n}"}
    description "Some Date Range description"
    active true
    company_id 1
    created_by_id 1
    updated_by_id 1
  end
end
