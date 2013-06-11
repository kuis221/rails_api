# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :day_item, :class => 'DayItems' do
    day_part ""
    start_time "MyString"
    end_time "MyString"
  end
end
