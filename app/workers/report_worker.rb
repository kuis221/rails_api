class ReportWorker
  include Resque::Plugins::UniqueJob
  @queue = :export

  def self.perform(report_id)
    report = Report.find(report_id)
    begin
      report.generate_report
    rescue  Exception => e
      report.fail!
      raise e
    end
  end
end