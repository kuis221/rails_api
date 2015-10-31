class ListExportWorker
  include Sidekiq::Worker
  sidekiq_options queue: :export, retry: false

  #extend HerokuResqueAutoScale
  #
  sidekiq_retries_exhausted do |msg|
    export = ListExport.find(msg['args'][0])
    export.fail!
  end

  def perform(download_id)
    NewRelic::Agent.ignore_apdex
    NewRelic::Agent.ignore_enduser
    ListExport.find(download_id).export_list
  end
end
