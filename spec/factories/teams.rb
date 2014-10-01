# == Schema Information
#
# Table name: teams
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  active        :boolean          default(TRUE)
#  company_id    :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :team do
    sequence(:name) { |n| "Team #{n}" }
    description 'Team description'
    created_by_id 1
    updated_by_id 1
    active true
    company_id 1

    ignore do
      user_ids nil
      campaign_ids nil
    end

    after(:create) do |event, evaluator|
      event.campaign_ids = evaluator.campaign_ids if evaluator.campaign_ids
      event.user_ids = evaluator.user_ids if evaluator.user_ids
      event.save if evaluator.campaign_ids || evaluator.user_ids
    end
  end
end
