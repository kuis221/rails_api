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
