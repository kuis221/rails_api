# == Schema Information
#
# Table name: venues
#
#  id                   :integer          not null, primary key
#  company_id           :integer
#  place_id             :integer
#  events_count         :integer
#  promo_hours          :decimal(8, 2)    default(0.0)
#  impressions          :integer
#  interactions         :integer
#  sampled              :integer
#  spent                :decimal(10, 2)   default(0.0)
#  score                :integer
#  avg_impressions      :decimal(8, 2)    default(0.0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  avg_impressions_hour :decimal(6, 2)    default(0.0)
#  avg_impressions_cost :decimal(8, 2)    default(0.0)
#  score_impressions    :integer
#  score_cost           :integer
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :venue do
    company_id 1
    place_id nil
    events_count 1
    promo_hours 9.5
    impressions 100
    interactions 100
    sampled 100
    spent 1000.00
    score 90
    avg_impressions 50.00
    avg_impressions_hour 5.00
    avg_impressions_cost 1.00
    score_impressions 100
    score_cost 1000
  end
end
