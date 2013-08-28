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

require 'spec_helper'

describe AssetDownload do
  pending "add some examples to (or delete) #{__FILE__}"
end
