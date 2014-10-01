class AssetsDownloadWorker
  include Resque::Plugins::UniqueJob
  @queue = :download

  def self.perform(download_id)
    download = AssetDownload.find(download_id)
    begin
      download.process!
    rescue AWS::S3::Errors::RequestTimeout
      download.process! # Try again
    end
  end
end
