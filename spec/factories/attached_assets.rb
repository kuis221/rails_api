# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :attached_asset do
    file_file_name "filetest.jpg"
    file_file_size 12345
    file_content_type "image/jpg"
    file_updated_at Time.now
    attachable nil
    created_by_id 1
    updated_by_id 1
    processed true

    factory :document do
      asset_type 'document'
    end

    factory :photo do
      asset_type 'photo'
    end
  end
end
