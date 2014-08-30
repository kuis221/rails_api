# == Schema Information
#
# Table name: filter_settings
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  apply_to        :string(255)
#  settings        :text
#  created_at      :datetime
#  updated_at      :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :filter_setting do
    company_user nil
    apply_to "events"
    settings "MyText"
  end
end
