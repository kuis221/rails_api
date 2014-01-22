class KpiReportWorker
  include Resque::Plugins::UniqueJob
  @queue = :export

  def self.perform(report_id)
    report = KpiReport.find(report_id)
    report.generate_report
  end
end