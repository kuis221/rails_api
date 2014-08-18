# == Schema Information
#
# Table name: campaigns
#
#  id               :integer          not null, primary key
#  name             :string(255)
#  description      :text
#  aasm_state       :string(255)
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  company_id       :integer
#  first_event_id   :integer
#  last_event_id    :integer
#  first_event_at   :datetime
#  last_event_at    :datetime
#  start_date       :date
#  end_date         :date
#  survey_brand_ids :integer          default([])
#  modules          :text
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :campaign do
    sequence(:name) {|n| "Campaign #{n}" }
    description "Test Campaign description"
    aasm_state "active"
    association :company
    created_by_id 1
    updated_by_id 1

    ignore do
      user_ids nil
      team_ids nil
    end

    after(:create) do |event, evaluator|
      event.team_ids = evaluator.team_ids if evaluator.team_ids
      event.user_ids = evaluator.user_ids if evaluator.user_ids
      event.save if evaluator.team_ids || evaluator.user_ids
    end

    factory :inactive_campaign do
      aasm_state 'inactive'
    end
  end
end
