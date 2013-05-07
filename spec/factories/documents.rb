# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :document, :class => 'Documents' do
    name "MyString"
    file ""
    documentable nil
    created_by_id 1
    updated_by_id 1
  end
end
