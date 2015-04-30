# == Schema Information
#
# Table name: attached_assets
#
#  id                    :integer          not null, primary key
#  file_file_name        :string(255)
#  file_content_type     :string(255)
#  file_file_size        :integer
#  file_updated_at       :datetime
#  asset_type            :string(255)
#  attachable_id         :integer
#  attachable_type       :string(255)
#  created_by_id         :integer
#  updated_by_id         :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  active                :boolean          default(TRUE)
#  direct_upload_url     :string(255)
#  rating                :integer          default(0)
#  folder_id             :integer
#  status                :integer          default(0)
#  processing_percentage :integer          default(0)
#

require 'rails_helper'

describe AttachedAsset, type: :model do
  it { is_expected.to belong_to(:attachable) }
  it { is_expected.to belong_to(:folder) }

  it { is_expected.to validate_presence_of(:attachable) }

  describe 'direct_upload_url validations' do
    before { subject.file_file_name = nil }

    it { is_expected.to validate_presence_of(:direct_upload_url) }
  end

  describe '#activate' do
    let(:attached_asset) { build(:attached_asset, active: false) }

    it 'should return the active value as true' do
      attached_asset.activate!
      attached_asset.reload
      expect(attached_asset.active).to be_truthy
    end
  end

  describe '#deactivate' do
    let(:attached_asset) { build(:attached_asset, active: false) }

    it 'should return the active value as false' do
      attached_asset.deactivate!
      attached_asset.reload
      expect(attached_asset.active).to be_falsey
    end
  end
end
