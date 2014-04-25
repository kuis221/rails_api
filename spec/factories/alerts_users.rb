# == Schema Information
#
# Table name: alerts_users
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  name            :string(255)
#  version         :integer
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :alerts_user do
    company_user nil
    name "feature_name"
    version 1
  end
end
