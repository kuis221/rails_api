# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :comment do
    commentable nil
    content "MyText"
    created_by_id 1
    updated_by_id 1
  end
end
