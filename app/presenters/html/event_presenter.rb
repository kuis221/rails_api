module Html
  class EventPresenter < BasePresenter
    # What event phase to render
    def current_phase
      [h.params[:phase], phases[:current_phase]].delete_if(&:blank?).first.to_sym
    end

    def event_members_name(line_separator = '<br />')
      return if users.nil? && teams.nil?
      members = []
      users.each do |team_member|
        members.push team_member.full_name if team_member.full_name.present?
      end unless users.nil?

      teams.each do |team|
        members.push team.name if team.name.present?
      end unless teams.nil?

      members_list = members.compact.sort.join(line_separator) unless members.compact.empty?
      members_list.html_safe if members_list.present?
    end

    def date_range_basic_info(options={})
      return if start_at.nil?
      return format_date_with_time(start_at) if end_at.nil?
      options[:date_separator] ||= ' - '
      if start_at.to_date != end_at.to_date
        the_date = format_date(start_at, true)
        the_date += options[:date_separator].html_safe
        the_date += format_date(end_at, true).html_safe
        the_date += " <b>from</b> #{start_at.strftime('%l:%M %p').strip} <b>to</b> #{end_at.strftime('%l:%M %p').strip}".html_safe
      else
        if start_at.strftime('%Y') == Time.zone.now.year.to_s
          the_date = start_at.strftime('%^a %b %e').html_safe
        else
          the_date = start_at.strftime('%^a %b %e, %Y').html_safe
        end
        the_date += " <b>from</b> #{start_at.strftime('%l:%M %p').strip} <b>to</b> #{end_at.strftime('%l:%M %p').strip}".html_safe
      end
      the_date.html_safe
    end

    def date_range_for_details_bar(options={})
      return if start_at.nil?
      return format_date_with_time(start_at, true, false) if end_at.nil?
      options[:date_separator] ||= ' - '
      if start_at.to_date != end_at.to_date
        format_date_with_time(start_at, true, false) +
        options[:date_separator].html_safe +
        format_date_with_time(end_at, true, false)
      else
        if start_at.strftime('%Y') == Time.zone.now.year.to_s
          the_date = start_at.strftime('%b %e' + options[:date_separator]).html_safe
        else
          the_date = start_at.strftime('%b %e, %Y' + options[:date_separator]).html_safe
        end
        the_date += "#{start_at.strftime('%l:%M %p').strip} - #{end_at.strftime('%l:%M %p').strip}".html_safe
        the_date
      end
    end

    def date_range(options={})
      return if start_at.nil?
      return format_date_with_time(start_at) if end_at.nil?
      options[:date_separator] ||= '<br />'
      options[:date_only] ||= false
      if start_at.to_date != end_at.to_date
        if options[:date_only]
          format_date(start_at) +
          options[:date_separator].html_safe +
          format_date(end_at)
        else
          format_date_with_time(start_at) +
          options[:date_separator].html_safe +
          format_date_with_time(end_at)
        end
      else
        if start_at.strftime('%Y') == Time.zone.now.year.to_s
          the_date = start_at.strftime('%^a <b>%b %e</b>' + options[:date_separator]).html_safe
        else
          the_date = start_at.strftime('%^a <b>%b %e, %Y</b>' + options[:date_separator]).html_safe
        end
        the_date += "#{start_at.strftime('%l:%M %p').strip} - #{end_at.strftime('%l:%M %p').strip}".html_safe unless options[:date_only]
        the_date
      end
    end


    def format_date(the_date, plain = false, day_name = true)
      unless the_date.nil?
        if plain
          if the_date.strftime('%Y') == Time.zone.now.year.to_s
            the_date.strftime("#{'%^a ' if day_name}%b %e")
          else
            the_date.strftime("#{'%^a ' if day_name}%b %e, %Y")
          end
        else
          if the_date.strftime('%Y') == Time.zone.now.year.to_s
            the_date.strftime("#{'%^a ' if day_name}<b>%b %e</b>").html_safe
          else
            the_date.strftime("#{'%^a ' if day_name}<b>%b %e, %Y</b>").html_safe
          end
        end
      end
    end

    def format_date_with_time(date, plain = false, day_name = true)
      if plain
        if date.strftime('%Y') == Time.zone.now.year.to_s
          date.strftime("#{'%^a ' if day_name}%b %e at %l:%M %p").html_safe unless date.nil?
        else
          date.strftime("#{'%^a ' if day_name}%b %e, %Y at %l:%M %p").html_safe unless date.nil?
        end
      else
        if date.strftime('%Y') == Time.zone.now.year.to_s
          date.strftime("#{'%^a ' if day_name}<b>%b %e</b> at %l:%M %p").html_safe unless date.nil?
        else
          date.strftime("#{'%^a ' if day_name}<b>%b %e, %Y</b> at %l:%M %p").html_safe unless date.nil?
        end
      end
    end

    def team_members
      return if users.nil? && teams.nil?
      teams_tags.html_safe + users_tags.html_safe
    end

    def teams_tags
      return if teams.nil?
      team_list = ''
      teams.each do |team|
        team_list = h.content_tag(:div, class: 'user-tag') do
          h.content_tag(:div, class: 'user-type') do
            h.content_tag(:i, '', class: 'icon-team')
          end +
          h.content_tag(:span, team.name)
        end.html_safe
      end
      team_list
    end

    def users_tags
      return if users.nil?
      users.map do |team_member|
        h.content_tag(:div, class: 'user-tag has-tooltip', data: { title: h.contact_info_tooltip(team_member).to_str, trigger: :click, container: 'body' } ) do
          h.content_tag(:div, class: 'user-type') do
            h.content_tag(:i, '', class: 'icon-user')
          end +
          h.content_tag(:span, team_member.full_name)
        end
      end.join.html_safe
    end

    def current_phase_steps
      return if phases.nil?
      (name, steps) = phases[:phases].find { |name, _| name == current_phase }
      index_phase = phases[:phases].keys.index(phases[:current_phase])
      h.content_tag(:div, class: "step phase-id #{'active' if name == phases[:current_phase]}") do
        h.content_tag(:span, index_phase + 1, class: 'id') +
        name.to_s.upcase
      end + phase_steps(name, steps)
    end

    def phase_steps(phase, steps)
      return if steps.nil?
      step_last_id = steps.last[:id]
      steps.map do |step|
        h.content_tag(:div, class: "step #{'last-step' if step_last_id == step[:id]} #{'pending' unless step[:complete]}") do
          h.content_tag(:div, class: 'icon-connect') do
            h.content_tag(:i, '', class: "#{step[:complete] ? 'icon-check-circle' : 'icon-circle'}")
          end + h.content_tag(:div, class: 'phase-name') do
            h.link_to(step[:title].upcase, "#event-#{step[:id]}", class: 'smooth-scroll event-phase-step',
              data:{ message: I18n.t("instructive_messages.#{phase}.#{step[:id]}.add"), message_color: 'green'})
          end
        end
      end.join.html_safe
    end

    def render_nav_phases
      return if phases.nil?
      phases[:phases].each_with_index.map do |phase, i|
        h.content_tag(:div, class: 'phase-container') do
          render_nav_phase( phase, i)
        end
      end.join.html_safe
    end

    def render_nav_phase(phase, i)
      return if phase.nil?
      index_phase = phases[:phases].keys.index(phases[:current_phase])
      completed = i <= index_phase
      h.content_tag(:div, class: "step phase-id #{'active' if phase[0] == phases[:current_phase]}") do
        (completed ? h.content_tag(:div, '', class: 'icon-check-circle') : h.content_tag(:span, i + 1, class: 'id')) +
        phase[0].upcase
      end + phase_steps(phase[0], phase[1])
    end

    #should be removed
    def current_phases_indicator
      return if phases.nil?
      completed_index = phases[:phases].keys.index(phases[:current_phase])
      phases[:phases].each_with_index.map do |phase, i|
        h.content_tag(:span, class: "step #{'active' if phase[0] == current_phase} #{'completed' if i <= completed_index && phase[0] != current_phase} #{@model.aasm_state}#{@model.late? && @model.unsent? ? ' late' : '' }") do
          value_phase =  i <= completed_index && phase[0] != current_phase ? h.content_tag(:i, '', class: 'icon-checked') : i + 1
          h.content_tag(:span, value_phase, class: 'circle-step') do
            phase_link(phase[0], i <= completed_index && phase[0] != current_phase, value_phase)
          end +
          phase_link(phase[0], i <= completed_index && phase[0] != current_phase)
        end
      end.join.html_safe
    end

    def phase_link(phase, linked, label = '')
      h.link_to_if linked, label.present? ? label : phase.to_s.upcase,
                   h.phase_event_path(@model, phase: phase,
                                              return: h.return_path)
    end
  end
end
