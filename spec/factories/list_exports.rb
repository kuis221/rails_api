# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :list_export do
    list_class "MyString"
    params "MyString"
    export_format "MyString"
    aasm_state "MyString"
    user nil
  end
end
