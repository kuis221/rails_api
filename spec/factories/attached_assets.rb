# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :attached_asset, :class => 'AttachedAssets' do
    name "MyString"
    file ""
    attachable nil
    created_by_id 1
    updated_by_id 1
  end
end
