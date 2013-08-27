# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :asset_download do
    uid "MyString"
    user nil
    last_download "2013-08-26 16:31:12"
  end
end
