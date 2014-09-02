# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :brand_ambassadors_document, :class => 'BrandAmbassadors::Document' do
    file_file_name "filetest.jpg"
    file_file_size 12345
    file_content_type "image/jpg"
    file_updated_at Time.now
    asset_type 'ba_document'
    processed true
    active true
  end
end
