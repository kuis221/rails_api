module Analysis
  module StaffReportHelper
    def staff_report_data
      @staff_data ||= begin
        data = load_events_and_promo_hours_data

        data['events_this_month'] = 0
        data['events_last_month'] = 0
        data['events_this_week'] = 0
        data['events_next_week'] = 0
        data['promo_hours_this_month'] = 0
        data['promo_hours_last_month'] = 0
        data['promo_hours_this_week'] = 0
        data['promo_hours_next_week'] = 0

        # raise data['days'].inspect

        (1.month.ago.beginning_of_month.to_date..1.month.ago.end_of_month.to_date).each do |day|
          d = day.to_s(:numeric)
          if data['days'].key?(d)
            data['events_last_month'] += data['days'][d]['approved_events']
            data['promo_hours_last_month'] += data['days'][d]['approved_promo_hours']
          end
        end

        (Time.zone.now.beginning_of_month.to_date..Time.zone.now.end_of_month.to_date).each do |day|
          d = day.to_s(:numeric)
          if data['days'].key?(d)
            data['events_this_month'] += data['days'][d]['approved_events']
            data['promo_hours_this_month'] += data['days'][d]['approved_promo_hours'] if data['days'].key?(d)
          end
        end

        (Time.zone.now.beginning_of_week.to_date..Time.zone.now.end_of_week.to_date).each do |day|
          d = day.to_s(:numeric)
          if data['days'].key?(d)
            data['events_this_week'] += data['days'][d]['approved_events']
            data['promo_hours_this_week'] += data['days'][d]['approved_promo_hours']
          end
        end

        (1.week.from_now.beginning_of_week.to_date..1.week.from_now.end_of_week.to_date).each do |day|
          d = day.to_s(:numeric)
          if data['days'].key?(d)
            data['events_next_week'] += data['days'][d]['approved_events']
            data['promo_hours_next_week'] += data['days'][d]['approved_promo_hours']
          end
        end

        data
      end
    end
  end
end
