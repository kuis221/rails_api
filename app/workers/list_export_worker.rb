class ListExportWorker
  include Resque::Plugins::UniqueJob
  @queue = :export

  extend HerokuResqueAutoScale

  def self.perform(download_id)
    export = ListExport.find(download_id)
    export.export_list

  rescue Resque::TermException
    # if the worker gets killed, (when deploying for example)
    # re-enqueue the job so it will be processed when worker is restarted
    Resque.enqueue(ListExportWorker, download_id)

  rescue  Exception => e
    Rails.logger.debug e.message
    Rails.logger.debug e.backtrace.inspect
    export.fail!
    raise e
  end
end