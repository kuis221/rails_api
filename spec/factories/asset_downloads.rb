# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :asset_download do
    assets_ids nil
    aasm_state "new"
    uid "asdfghjkl"
    file_file_name "filetest.jpg"
    file_file_size 12345
    file_content_type "image/jpg"
    file_updated_at Time.now
    user_id nil
    last_downloaded "2013-08-26 16:31:12"
  end
end
