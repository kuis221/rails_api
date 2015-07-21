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
      when 'Number', 'Currency'
        results_for_number(form_field)
      when 'Summation'
        results_for_summation(form_field)
      when 'Percentage', 'Checkbox', 'Radio'
        results_for_percentage_chart(form_field)
      when 'LikertScale'
        results_for_likert_scale(form_field)
      end
    end

    def results_for_number(form_field)
      total = 0
      events.active.each do |event|
        result = event.results_for([form_field]).first
        total += result.try(:value).to_f
      end
      "#{'$' if form_field.type_name == 'Currency'}#{total}"
    end

    def results_for_summation(form_field)
      totals = initialize_totals(form_field)

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
      totals = initialize_totals(form_field)

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

    def results_for_likert_scale(form_field)
      totals = form_field.statements.inject({}) do |memo, (statement)|
        memo[statement.id] = {
          name: statement.name,
          totals: form_field.options.inject({}) do |m, (option)|
              m[option.id] = { name: option.name, total: 0 }
              m
          end
        }
        memo
      end

      events.active.each do |event|
        result = event.results_for([form_field]).first
        if result.hash_value.present?
          result.hash_value.map do |(key, value)|
            totals[key.to_i][:totals][value.to_i][:total] += 1
          end
        end
      end

      totals.map do |(key, statement)|
        [key, statement[:name], totals_likert_scale(statement[:totals])]
      end
    end

    def totals_likert_scale(totals)
      values = totals.reject{ |_, v| v[:total].nil? || v[:total] == '' || v[:total].to_f == 0.0 }
      values.map{ |_, v| [v[:name], v[:total]] }
    end

    def initialize_totals(form_field)
      form_field.options_for_input.inject({}) do |memo, (_, id)|
        memo[id] = 0
        memo
      end
    end

    def gender_total(data)
      male = data.detect { |n| n[0] == 'Male' }
      female = data.detect { |n| n[0] == 'Female' }

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

    def result_for_age(form_field)
      totals = initialize_totals(form_field)

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

      total = totals.inject(0) {|total, (_, value)| total += value }
      options_map = Hash[form_field.options_for_input.map{|o| [o[1], o[0]] }]
      totals.inject({}) do |memo, (key, value)|
        memo[options_map[key]] = percent_of(value, total).round(2)
        memo
      end
    end
  end
end
