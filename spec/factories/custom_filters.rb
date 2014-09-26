# == Schema Information
#
# Table name: custom_filters
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  apply_to   :string(255)
#  filters    :text
#  created_at :datetime
#  updated_at :datetime
#  owner_id   :integer
#  owner_type :string(255)
#  group      :string(255)
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :custom_filter do
    owner nil
    sequence(:name) { |n| "Area #{n}" }
    apply_to 'events'
    filters 'param=true'
    group 'Saved Filters'
  end
end
