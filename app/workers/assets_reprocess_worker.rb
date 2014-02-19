class AssetsReprocessWorker
  @queue = :migration

  def self.perform(limit, offset)
    AttachedAsset.limit(limit).offset(offset).each do |a|
      begin
        a.file.reprocess!
      rescue Timeout::Error
        sleep(3)
        retry
      end
    end
  end
end