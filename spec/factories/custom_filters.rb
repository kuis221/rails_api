# == Schema Information
#
# Table name: custom_filters
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  name            :string(255)
#  apply_to        :string(255)
#  filters         :text
#  created_at      :datetime
#  updated_at      :datetime
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :custom_filter do
    owner nil
    sequence(:name) {|n| "Area #{n}" }
    apply_to "events"
    filters "param=true"
    group "Saved Filters"
  end
end
