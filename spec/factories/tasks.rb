# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :task do
    event_id 1
    title "MyString"
    due_at "2013-05-02 15:56:44"
    company_user_id 1
    completed false
  end
end
