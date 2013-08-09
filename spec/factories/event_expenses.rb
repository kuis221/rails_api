# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :event_expense do
    event nil
    name "MyString"
    amount "9.99"
    file ""
  end
end
