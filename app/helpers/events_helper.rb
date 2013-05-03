module EventsHelper
  def event_date_range(event)
    if event.start_at.to_date == event.end_at.to_date
      "#{event.start_date} #{event.start_time} - #{event.end_time}"
    else
      "#{event.start_date} #{event.start_time} -  #{event.end_date} #{event.end_time}"
    end
  end
end
