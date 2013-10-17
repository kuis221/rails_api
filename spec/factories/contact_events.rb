# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :contact_event do
    contactable nil
    event nil
  end
end
