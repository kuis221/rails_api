module Analysis
  module StaffReportHelper
    def staff_report_data
      tz = Time.zone.now.strftime('%Z')
      date_convert = "to_char(TIMEZONE('UTC', start_at) AT TIME ZONE '#{tz}', 'YYYY/MM/DD')"

      scope = Event.with_user_in_team(@company_user)
              .select("count(events.id) as events_count, sum(promo_hours) as promo_hours, #{date_convert} as event_start, events.aasm_state as group_recap_status")
              .group("#{date_convert}, events.aasm_state")
              .order(date_convert)

    end
  end
end