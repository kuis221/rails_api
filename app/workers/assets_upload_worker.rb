class AssetsUploadWorker
  include Sidekiq::Worker
  sidekiq_options queue: :upload, retry: 3

  def perform(asset_id, asset_class = 'AttachedAsset')
    klass ||= asset_class.constantize
    asset = klass.find(asset_id)
    return if asset.processed?
    asset.queued! unless asset.queued?
    asset.transfer_and_cleanup
  end
end
