# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :task do
    event nil
    title "MyString"
    due_at "2013-05-02 15:56:44"
    user nil
    completed false
  end
end
