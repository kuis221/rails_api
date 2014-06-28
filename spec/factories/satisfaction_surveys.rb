# == Schema Information
#
# Table name: satisfaction_surveys
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  session_id      :string(255)
#  rating          :string(255)
#  feedback        :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :satisfaction_survey do
    company_user nil
    session_id "43e4be6b8745c80f693b2936924a865a"
    rating "positive"
    feedback "My feedback"
  end
end
