class KpiReportWorker
  include Resque::Plugins::UniqueJob
  @queue = :export

  extend HerokuResqueAutoScale

  def self.perform(report_id)
    report = KpiReport.find(report_id)
    Company.current = report.company_user.company
    report.generate_report
  end
end