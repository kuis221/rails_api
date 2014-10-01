# == Schema Information
#
# Table name: asset_downloads
#
#  id                :integer          not null, primary key
#  uid               :string(255)
#  assets_ids        :text
#  aasm_state        :string(255)
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  user_id           :integer
#  last_downloaded   :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :asset_download do
    assets_ids nil
    aasm_state 'new'
    uid 'asdfghjkl'
    file_file_name 'filetest.jpg'
    file_file_size 12_345
    file_content_type 'image/jpg'
    file_updated_at Time.now
    user_id nil
    last_downloaded '2013-08-26 16:31:12'
  end
end
