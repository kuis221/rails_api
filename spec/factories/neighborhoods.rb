# == Schema Information
#
# Table name: neighborhoods
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  city       :string(255)
#  state      :string(255)
#  county     :string(255)
#  country    :string(255)
#  geometry   :text
#  created_at :datetime
#  updated_at :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :neighborhood do
    name "MyString"
    city "MyString"
    state "MyString"
    county "MyString"
    country "MyString"
    geometry "MyText"
  end
end
