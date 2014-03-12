class ListExportWorker
  include Resque::Plugins::UniqueJob
  @queue = :export

  def self.perform(download_id)
    export = ListExport.find(download_id)
    begin
      export.export_list
    rescue  Exception => e
      Rails.logger.debug e.message
      Rails.logger.debug e.backtrace.inspect
      export.fail!
      raise e
    end
  end
end