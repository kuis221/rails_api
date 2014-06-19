class AssetsUploadWorker
  include Resque::Plugins::UniqueJob
  @queue = :upload

  extend HerokuResqueAutoScale

  def self.perform(asset_id)
    tries ||= 3
    asset = AttachedAsset.find(asset_id)
    asset.transfer_and_cleanup
  rescue Errno::ECONNRESET, Net::ReadTimeout, Net::ReadTimeout => e
    tries -= 1
    if tries > 0
      sleep(3)
      retry
    else
      raise e
    end
  end
end