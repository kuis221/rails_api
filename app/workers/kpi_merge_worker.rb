class KpiMergeWorker
  include Resque::Plugins::UniqueJob
  @queue = :export

  def self.perform(ids, options)
    kpis = Kpi.where(id: ids).merge_fields(options)
  end
end
