class ReportWorker
  include Resque::Plugins::UniqueJob
  @queue = :export

  def self.perform(report_id)
    report = Report.find(report_id)
    report.generate_report
  end
end