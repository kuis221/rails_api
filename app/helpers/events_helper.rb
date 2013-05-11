module EventsHelper
  def event_date_range(event)
    if event.start_at.to_date == event.end_at.to_date
      "#{event.start_date} #{event.start_time} - #{event.end_time}"
    else
      "#{event.start_date} #{event.start_time} -  #{event.end_date} #{event.end_time}"
    end
  end

  def event_tasks_progress_bar(tasks)
    total = tasks.count
    if total > 0
      completed = tasks.select{|t| t.completed?}.count
      completed_p = (100 * completed / total).to_i
      assigned = tasks.select{|t| !t.user_id.nil? }.count
      assigned_p = (100 * assigned / total).to_i

      content_tag(:div, "#{assigned} of #{total} Tasks Have Been Assigned. #{completed} are Completed.") +
      content_tag(:div, class: :progress) do
        content_tag(:div, "#{completed_p}%", class: 'bar bar-completed', style: "width: #{completed_p}%") +
        content_tag(:div, "#{assigned_p - completed_p}%", class: 'bar bar-assigned', style: "width: #{assigned_p - completed_p}%") +
        content_tag(:div, "#{100-assigned_p}%", class: 'bar-unassigned', style: "width: #{100-assigned_p}%")
      end
    end
  end
end
