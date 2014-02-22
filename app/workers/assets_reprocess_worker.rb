class AssetsReprocessWorker
  @queue = :migration

  def self.perform(i, style)
      a.file.reprocess! style
    end
  end
end