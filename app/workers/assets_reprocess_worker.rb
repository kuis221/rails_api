class AssetsReprocessWorker
  @queue = :migration

  def self.perform(id, style)
    asset = AttachedAsset.find(id)
    asset.file.reprocess! style
  end
end