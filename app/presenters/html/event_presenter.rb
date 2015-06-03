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

    def render_nav_phases
      return if phases.nil?
      index_phase = phases[:phases].keys.index(phases[:current_phase])
      h.content_tag(:ul, id: 'event-phases-step', class: 'unstyled phases-list') do
        phases[:phases].each_with_index.map do |phase, i|
          completed = i <= index_phase
          h.content_tag(:li, class: "#{'active-phase' if phase[0] == phases[:current_phase]} #{'completed' if completed}") do
            h.content_tag(:span, class: 'phase-id') do
              phase_link(phase[0], completed && phase[0] != current_phase, (i + 1).to_s)
            end +
            h.content_tag(:b, phase_link(phase[0], completed && phase[0] != current_phase), class: 'phase') +
            phase_steps(phase)
          end
        end.join.html_safe
      end
    end

    def phase_steps(phase)
      return unless current_phase == phase[0]
      h.content_tag(:ul, class: 'unstyled phase-steps') do
        phase[1].each.map do |step|
          list_step = step[:complete] ?  h.content_tag(:i, '', class: 'icon-checked') : ''
          list_step << h.link_to(step[:title], "#event-#{step[:id]}", class: 'smooth-scroll')
          list_step << ' '.html_safe + h.content_tag(:span, "(optional)", class: 'optional') unless step[:required]
          h.content_tag(:li, list_step.html_safe, class: "#{'completed' if step[:complete]}")
        end.join.html_safe
      end
    end

    def current_step_indicator
      return if phases.nil?
      (name, steps) = phases[:phases].find { |name, _| name == current_phase }
      h.content_tag(:ul, class: 'switch-list unstyled') do
        steps.each.each_with_index.map do |step, i|
          h.content_tag(:li) do
            h.content_tag(:a, class: 'small no-decorate collapsed', 'aria-expanded': true, 'aria-controls': 'event-details-collapse',
              data: { toggle: 'collapse', spytarget: (i == 0 ? '#application-body' : "#event-#{step[:id]}") }, href: '#event-details-collapse') do
              h.content_tag(:span, phases[:phases].keys.index(name) + 1, class: 'phase-id') +
                h.content_tag(:b, "#{name.to_s.upcase}: #{step[:title]}") +
                h.content_tag(:span, '', class: 'arrow')
            end
          end
        end.join.html_safe
      end
    end

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

    def guided_bar
      guided_message = Html::EventGuidedMessagePresenter.new(@model, h)
      steps = guided_message.current_steps
      h.content_tag(:div, class: "guide-bar text-center scrollspy-style event-details-scroll-spy #{@model.aasm_state}#{@model.late? && @model.unsent? ? ' late' : '' }") do
        h.content_tag(:ul, id: 'event-guided-step-nav', class: 'unstyled switch-list') do
          steps.each_with_index.map do |step, i|
            h.content_tag(:li,  data: { next: guided_message.next_target_after(step[:id]), prev: guided_message.prev_target_before(step[:id]) }) do
              [
                (i == 0 ? h.link_to('', '#application-body', data: { spytarget: '#application-body'}) : '') +
                guided_message.send("#{phases[:current_phase]}_#{step[:id]}")
              ].join.html_safe
            end
          end.join.html_safe
        end
      end
    end

    def phase_link(phase, linked, label = '')
      h.link_to_if linked, label.present? ? label : phase.to_s.upcase,
                   h.phase_event_path(@model, phase: phase,
                                              return: h.return_path)
    end
  end
end
