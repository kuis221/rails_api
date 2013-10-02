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
  it { should belong_to(:user) }

  it { should validate_presence_of(:uid) }

  describe "states" do
    before(:each) do
      @asset = FactoryGirl.create(:asset_download)
    end

    describe ":new" do
      it 'should be an initial state' do
        @asset.should be_new
      end

      it 'should change to :queued on :new or :complete' do
        @asset.queue
        @asset.should be_queued
      end

      it 'should change to :processing on :queued or :new' do
        @asset.should_receive(:compress_assets)
        @asset.process
        @asset.should be_processing
      end

      it 'should change to :completed on :processing' do
        @asset.should_receive(:compress_assets)
        @asset.process
        @asset.complete
        @asset.should be_completed
      end
    end
  end
end
