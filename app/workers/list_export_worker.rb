class ListExportWorker
  include Resque::Plugins::UniqueJob
  @queue = :export

  extend HerokuResqueAutoScale

  def self.perform(download_id)
    export = ListExport.find(download_id)
    require  Rails.root.join 'app/controllers/filtered_controller.rb'
    require  Rails.root.join 'app/controllers/' + export.controller.underscore+'.rb'
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