module Analysis
  module StaffReportHelper
    def staff_report_data
      @staff_data ||= begin
        data = load_events_and_promo_hours_data
      end
    end
  end
end