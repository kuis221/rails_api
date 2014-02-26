# == Schema Information
#
# Table name: notifications
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  message         :string(255)
#  level           :string(255)
#  path            :text
#  icon            :string(255)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  message_params  :text
#  extra_params    :text
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :notification do
    company_user nil
    message "MyString"
    level "MyString"
    path "MyText"
    icon "MyString"
  end
end
