module Html
  class CampaignPresenter < BasePresenter
    def date_range(options = {})
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

    def gender_total(data)
      male = data.find { |n| n[0] == 'Male' }
      female = data.find { |n| n[0] == 'Female' }

      total_male = male.present? ? male[1].round : 0
      total_female = female.present? ? female[1].round : 0
      total = total_male + total_female

      {
        male: percent_of(total_male, total).round,
        female: percent_of(total_female, total).round
      }
    end

    def percent_of(n, t)
      n.to_f / t.to_f * 100.0
    end
  end
end
