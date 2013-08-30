class AssetsUploadWorker
  include Resque::Plugins::UniqueJob
  @queue = :upload

  def self.perform(asset_id)
    asset = AttachedAsset.find(asset_id)
    asset.transfer_and_cleanup
  end
end