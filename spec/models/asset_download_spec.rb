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

require 'rails_helper'

describe AssetDownload, type: :model do
  it { is_expected.to belong_to(:user) }

  it { is_expected.to validate_presence_of(:uid) }

  describe 'states' do
    let(:asset) { create(:asset_download) }

    describe ':new' do
      it 'should be an initial state' do
        expect(asset).to be_new
      end

      it 'should change to :queued on :new or :complete' do
        asset.queue
        expect(asset.aasm_state).to eql 'queued'
      end

      it 'should change to :processing on :queued or :new' do
        expect(asset).to receive(:compress_assets)
        asset.process
        expect(asset).to be_processing
      end

      it 'should change to :completed on :processing' do
        expect(asset).to receive(:compress_assets)
        asset.process
        asset.complete
        expect(asset).to be_completed
      end
    end
  end
end
