# == Schema Information
#
# Table name: memberships
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  memberable_id   :integer
#  memberable_type :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  parent_id       :integer
#  parent_type     :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :membership do
    company_user nil
    member nil
  end
end
