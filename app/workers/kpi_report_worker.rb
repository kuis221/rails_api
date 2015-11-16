class KpiReportWorker
  include Sidekiq::Worker
  sidekiq_options queue: :export, retry: false

  def perform(report_id)
    report = KpiReport.find(report_id)
    Company.current = report.company_user.company
    report.generate_report
  end
end
