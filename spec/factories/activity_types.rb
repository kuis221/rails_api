# == Schema Information
#
# Table name: activity_types
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  description :text
#  active      :boolean          default(TRUE)
#  company_id  :integer
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :activity_type do
    sequence(:name) {|n| "Activity Type #{n}" }
    description "Activity Type description"
    active true
    company_id 1
  end
end
