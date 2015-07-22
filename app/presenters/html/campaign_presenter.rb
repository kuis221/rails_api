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

    def results_for(form_field, event_scope)
      return nil if form_field.blank?
      case form_field.type_name
      when 'Number', 'Currency'
        results_for_number(form_field, event_scope)
      when 'Summation'
        results_for_summation(form_field, event_scope)
      when 'Percentage', 'Checkbox'
        results_for_percentage_chart_for_hash(form_field, event_scope)
      when 'Radio', 'Dropdown'
        results_for_percentage_chart_for_value(form_field, event_scope)
      when 'LikertScale'
        results_for_likert_scale(form_field, event_scope)
      when 'Brand'
        results_for_brand(form_field, event_scope)
      end
    end

    def results_for_number(form_field, event_scope)
      result = form_field.grouped_results(id, event_scope).pluck('value')
      total = result.compact.inject{ |sum,x| sum.to_f + x.to_f } || 0

      "#{'$' if form_field.type_name == 'Currency'}#{total}"
    end

    def results_for_summation(form_field, event_scope)
      results_for_hash_values(form_field, event_scope)
    end

    def results_for_percentage_chart_for_hash(form_field, event_scope)
      totals = results_for_hash_values(form_field, event_scope)

      values = totals.reject{ |k, v| v.nil? || v == '' || v.to_f == 0.0 }
      options_map = Hash[form_field.options_for_input.map{|o| [o[1], o[0]] }]
      values.map{ |k, v| [options_map[k], v] }
    end

    def results_for_percentage_chart_for_value(form_field, event_scope)
      totals = form_field.grouped_results(id, event_scope)

      values = totals.reject{ |k, v| k == nil || v.nil? || v == '' || v.to_f == 0.0 }
      options_map = Hash[form_field.options_for_input.map{|o| [o[1], o[0]] }]
      values.map{ |k, v| [options_map[k.to_i], v] }
    end

    def results_for_hash_values(form_field, event_scope)
      result = form_field.grouped_results(id, event_scope).pluck('hash_value').select { |h| h unless h.blank? }
      return [] if result.blank?

      keys = form_field.options_for_input.map { |k, v| v.to_s }
      totals = Hash[keys.zip(result.map { |h| h.values_at(*keys) }.inject{ |a, v| a.zip(v).map{ |sum, t| sum.to_f + t.to_f} })]

      totals.inject({}) do |memo, (key, value)|
        memo[key.to_i] = value
        memo
      end
    end

    def results_for_brand(form_field, event_scope)
      totals = form_field.grouped_results(id, event_scope)
      return [] if totals.blank?

      values = totals.reject{ |k, v| k == nil || v.nil? || v == '' || v.to_f == 0.0 }
      r = events.first.results_for([form_field]).first
      options_map = Hash[form_field.options_for_field(r).pluck(:id, :name)]
      values.map{ |k, v| [options_map[k.to_i], v] }
    end

    def results_for_likert_scale(form_field, event_scope)
      result = form_field.grouped_results(id, event_scope).pluck('hash_value').select { |h| h unless h.blank? }
      return [] if result.blank?

      totals = initialize_totals_likert_scale(form_field)

      result.each do |value|
        value.map do |(k, v)|
          totals[k.to_i][:totals][v.to_i][:total] += 1
        end
      end

      totals.map do |(key, statement)|
        [key, statement[:name], totals_likert_scale(statement[:totals])]
      end
    end

    def initialize_totals_likert_scale(form_field)
      form_field.statements.inject({}) do |memo, (statement)|
        memo[statement.id] = {
          name: statement.name,
          totals: form_field.options.inject({}) do |m, (option)|
              m[option.id] = { name: option.name, total: 0 }
              m
          end
        }
        memo
      end
    end

    def totals_likert_scale(totals)
      values = totals.reject{ |_, v| v[:total].nil? || v[:total] == '' || v[:total].to_f == 0.0 }
      values.map{ |_, v| [v[:name], v[:total]] }
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

    def result_for_age(form_field, event_scope)

      totals = results_for_hash_values(form_field, event_scope)
      total = totals.inject(0) { |total, (_, value)| total += value unless value.blank? }

      options_map = Hash[form_field.options_for_input.map{ |o| [o[1], o[0]] }]
      totals.inject({}) do |memo, (key, value)|
        memo[options_map[key]] = percent_of(value, total).round(2)
        memo
      end
    end
  end
end
