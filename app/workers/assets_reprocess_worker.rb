class AssetsReprocessWorker
  @queue = :migration

  def self.perform(limit, offset)
    AttachedAsset.limit(limit).offset(offset).each do |a|
      a.file.reprocess!
    end
  end
end