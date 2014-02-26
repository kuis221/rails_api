class ReportWorker
  include Resque::Plugins::UniqueJob
  @queue = :export

  def self.perform(report_id)
    report = Report.find(report_id)
    Company.current = report.company_user.company
    report.generate_report
  end
end