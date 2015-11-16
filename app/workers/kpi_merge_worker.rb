class KpiMergeWorker
  include Sidekiq::Worker
  sidekiq_options queue: :export, retry: false

  def perform(ids, options)
    Kpi.where(id: ids).merge_fields(options)
  end
end
