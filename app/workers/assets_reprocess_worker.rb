class AssetsReprocessWorker
  @queue = :migration

  def self.perform(limit, offset)
    AttachedAsset.limit(limit).offset(offset).each do |a|
      tries = 3
      begin
        unless a.file.exists?(:thumbnail)
          a.file.reprocess!
        end
      rescue
        tries -= 1
        if tries >= 0
          sleep(3)
          retry
        else
          raise e
        end
      end
    end
  end
end