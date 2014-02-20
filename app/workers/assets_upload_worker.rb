class AssetsUploadWorker
  include Resque::Plugins::UniqueJob
  @queue = :upload

  def self.perform(asset_id)
    Resque::Plugins::Timeout.switch = :off
    tries ||= 3
    asset = AttachedAsset.find(asset_id)
    asset.transfer_and_cleanup
  rescue AWS::S3::Errors::NoSuchKey => e
    tries -= 1
    if tries > 0
      sleep(3)
      retry
    else
      raise e
    end
  end
end