# == Schema Information
#
# Table name: attached_assets
#
#  id                :integer          not null, primary key
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  asset_type        :string(255)
#  attachable_id     :integer
#  attachable_type   :string(255)
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  active            :boolean          default(TRUE)
#  direct_upload_url :string(255)
#  processed         :boolean          default(FALSE), not null
#  rating            :integer          default(0)
#  folder_id         :integer
#

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
    active true

    factory :document do
      asset_type 'document'
    end

    factory :photo do
      asset_type 'photo'
    end
  end
end
