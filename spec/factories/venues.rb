# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :venue do
    company nil
    place nil
    events 1
    promo_hours "9.99"
    impressions 1
    interactions 1
    sampled 1
    score 1
    avg_impressions 1
  end
end
