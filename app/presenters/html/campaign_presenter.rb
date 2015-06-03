module Html
  class CampaignPresenter < BasePresenter
    def date_range(options={})
      start_date_at = start_date || first_event_at
      end_date_at = end_date || last_event_at
      return if start_date_at.nil?
      return format_date_with_time(start_date_at) if end_date_at.nil?
      options[:date_only] ||= false

      if start_date_at.to_date != end_date_at.to_date
        format_date(start_date_at) + ' - ' + format_date(end_date_at)
      else
        if start_date_at.strftime('%Y') == Time.zone.now.year.to_s
          the_date = start_date_at.strftime('%^a <b>%b %e</b> - ').html_safe
        else
          the_date = start_date_at.strftime('%^a <b>%b %e, %Y</b> - ').html_safe
        end
        the_date
      end
    end
  end
end
