# == Schema Information
#
# Table name: neighborhoods
#
#  gid      :integer          not null, primary key
#  state    :string(2)
#  county   :string(43)
#  city     :string(64)
#  name     :string(64)
#  regionid :decimal(, )
#  geog     :spatial          multipolygon, 4326
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
