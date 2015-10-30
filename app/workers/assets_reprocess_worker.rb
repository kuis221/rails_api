class AssetsReprocessWorker
  include Sidekiq::Worker
  sidekiq_options queue: :migration

  def perform(id, style)
    asset = AttachedAsset.find(id)
    asset.file.reprocess! style
  end
end
