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

    def results_for(form_field)
      return nil if form_field.blank?
      case form_field.type_name
      when 'Number'
        results_for_number(form_field)
      when 'Summation'
        results_for_summation(form_field)
      when 'Percentage', 'Checkbox', 'Radio'
        results_for_percentage_chart(form_field)
      end
    end

    def results_for_number(form_field)
      total = 0
      events.active.each do |event|
        result = event.results_for([form_field]).first
        total += result.try(:value).to_f
      end
      total
    end

    def results_for_summation(form_field)
      totals = form_field.options.ids.inject({}) do |memo, values|
        memo[values] = 0
        memo
      end
      events.active.each do |event|
        result = event.results_for([form_field]).first
        if result.hash_value.present?
          form_field.options.ids.each do |key|
            totals[key] += result.hash_value[key.to_s].to_f if result.hash_value[key.to_s].present?
          end
        end
      end
      totals
    end

    def results_for_percentage_chart(form_field)
      totals = form_field.options_for_input.inject({}) do |memo, (_, id)|
        memo[id] = 0
        memo
      end

      events.active.each do |event|
        result = event.results_for([form_field]).first
        if result.hash_value.present? || result.value.present?
          form_field.options_for_input.each do |_, id|
            if form_field.type_name == 'Radio'
              totals[result.value.to_i] += 1 if id == result.value.to_i
            else
              totals[id] += result.hash_value[id.to_s].to_f if result.hash_value[id.to_s].present?
            end
          end
        end
      end

      values = totals.reject{ |k, v| v.nil? || v == '' || v.to_f == 0.0 }
      options_map = Hash[form_field.options_for_input.map{|o| [o[1], o[0]] }]
      values.map{ |k, v| [options_map[k], v] }
    end
  end
end
