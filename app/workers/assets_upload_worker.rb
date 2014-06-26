class AssetsUploadWorker
  include Resque::Plugins::UniqueJob
  @queue = :upload

  extend HerokuResqueAutoScale

  def self.perform(asset_id)
    tries ||= 3
    asset = AttachedAsset.find(asset_id)
    asset.transfer_and_cleanup

  rescue Resque::TermException
      # if the worker gets killed, (when deploying for example)
      # re-enqueue the job so it will be processed when worker is restarted
      Resque.enqueue(AssetsUploadWorker, asset_id)

  # AWS connections sometimes fail, so let's retry it a few times before raising the error
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