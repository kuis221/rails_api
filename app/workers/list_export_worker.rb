class ListExportWorker
  include Resque::Plugins::UniqueJob
  @queue = :download

  def self.perform(download_id)
    download = ListExport.find(download_id)
    begin
      download.process!
    rescue
      download.process! # Try again
    end
  end
end