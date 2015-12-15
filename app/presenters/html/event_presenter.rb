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

    def date_range_basic_info(options = {})
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

    def date_range_for_details_bar
      return if start_at.nil?
      return format_date_with_time(start_at, true, false) if end_at.nil?
      if start_at.to_date != end_at.to_date
        format_date_with_time(start_at, true, false) + ' - '.html_safe +
          format_date_with_time(end_at, true, false)
      else
        if start_at.strftime('%Y') == Time.zone.now.year.to_s
          the_date = start_at.strftime('%b %e' + ' - ').html_safe
        else
          the_date = start_at.strftime('%b %e, %Y' + ' - ').html_safe
        end
        the_date += "#{start_at.strftime('%l:%M %p').strip} - #{end_at.strftime('%l:%M %p').strip}".html_safe
        the_date
      end
    end

    def date_range(options = {})
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
        team_list += h.content_tag(:div, id: "event-team-#{team.id}", class: 'user-tag') do
          item =
            h.content_tag(:div, class: 'user-type') do
              h.content_tag(:i, '', class: 'icon-team')
            end +
            h.content_tag(:span, team.name)
          item +=
            h.link_to('',
                      h.delete_team_event_path(@model, team_id: team.to_param),
                      class: 'icon-close',
                      remote: true,
                      method: :delete,
                      title: 'Remove Team') if can?(:edit)
          item
        end.html_safe
      end
      team_list
    end

    def users_tags
      return if users.nil?
      users.map do |team_member|
        h.content_tag(:div, id: "event-member-#{team_member.id}", class: 'user-tag') do
          item =
            h.content_tag(:div, class: 'user-type') do
              h.content_tag(:i, '', class: 'icon-user')
            end +
            h.content_tag(:span, class: 'has-tooltip', data: { title: h.contact_info_tooltip(team_member).to_str,
                                                               trigger: :click,
                                                               container: 'body' }) do
              team_member.full_name
            end
          item +=
            h.link_to('',
                      h.delete_member_event_path(@model, member_id: team_member.to_param),
                      class: 'icon-close',
                      remote: true,
                      method: :delete,
                      title: 'Remove User') if can?(:edit)
          item
        end
      end.join.html_safe
    end

    def phase_steps(phase, index, steps)
      return if steps.nil? || steps.empty?
      current_phase_index = phases[:phases].keys.index(phases[:current_phase])
      steps.map do |step|
        button = h.content_tag(:div,
                               class: phase_step_clasess(step, steps.last[:id], steps.first[:id]),
                               data: { toggle: 'tooltip',
                                       title: step[:title].upcase,
                                       placement: 'top' }) do
          h.content_tag(:div, class: 'icon-connect') do
            h.content_tag(:i, '', class: "#{step[:complete] ? 'icon-check-circle' : 'icon-circle'}")
          end +
            h.content_tag(:div, step[:title].upcase, class: 'phase-name')
        end
        step_link(phase, step, button, index <= current_phase_index)
      end.join.html_safe
    end

    def phase_step_clasess(step, step_last_id, step_first_id)
      [
        'step',
        ('first-step' if step_first_id == step[:id]),
        ('last-step' if step_last_id == step[:id]),
        ('pending' unless step[:complete])
      ].compact.join(' ')
    end

    def step_link(phase, step, content, linked)
      url = target = "#event-#{step[:id]}"
      url = h.phase_event_path(@model, phase: phase, return: h.return_path) + target unless phase == current_phase
      h.link_to_if(linked, content, url,
                   class: 'smooth-scroll event-phase-step',
                   data: { message: guided_message(phase, step),
                           message_color: 'blue'
                         }.merge(phase == current_phase ? { spytarget: target } : {})) do
        if phase == :execute
          h.link_to content, '#', class: 'event-phase-step', data: { message: guided_message_presenter.locked_in_phase_plan_message, message_color: 'blue' }
        else
          content
        end
      end
    end

    def phases_with_accessible_steps
      phases[:phases].map do |phase_name, steps|
        [phase_name, user_accessible_steps(steps)]
      end
    end

    def user_accessible_steps(steps)
      steps.select { |s| !s.key?(:if) || h.instance_exec(@model, &s[:if]) }
    end

    def render_nav_phases
      return if phases.nil?
      event_phases = phases_with_accessible_steps
      max_steps = event_phases.map { |p| p[1].count }.max
      current_phase_index = phases[:phases].keys.index(current_phase)
      event_phases.each_with_index.map do |phase, i|
        h.content_tag(:div, class: "phase-container steps-#{max_steps} #{i == current_phase_index ? 'active' : 'hide'}") do
          render_nav_phase(phase, i) + phase_buttons(phase)
        end
      end.join.html_safe
    end

    def render_nav_phase(phase, i)
      return if phase.nil?
      index_phase = phases[:phases].keys.index(phases[:current_phase])
      completed = i < index_phase
      h.link_to_if(i <= index_phase,
                   h.content_tag(:div, class: phase_clasess(phase, i, index_phase)) do
                     (if completed
                        h.content_tag(:div, '', class: 'icon-check-circle')
                      else
                        phase_number = "#{i + 1}#{icon(:lock) if i > index_phase}".html_safe
                        h.content_tag(:span, phase_number.html_safe, class: 'id')
                      end) + phase[0].upcase
                   end, h.phase_event_path(@model, phase: phase[0], return: h.return_path)) + phase_steps(phase[0], i, phase[1])
    end

    def phase_clasess(phase, i, index_phase)
      [
        'step', 'phase-id',
        ('active' if phase[0] == phases[:current_phase]),
        ('locked' if i > index_phase)
      ].compact.join(' ')
    end

    def phase_buttons(phase)
      buttons =
        case phase[0]
        when :execute
          [submit_button]
        when :results
          approve_reject_buttons
        else
          []
        end.compact
      h.content_tag(:div, class: 'step actions') do
        buttons.join.html_safe + complete_percentage(phase)
      end
    end

    def complete_percentage(phase)
      return '' if phase[1].nil? || phase[1].empty?
      required_steps = phase[1].select { |s| s[:required] }
      return '100% COMPLETE' if required_steps.empty?
      completed_steps = phase[1].count { |s| s[:complete] && s[:required] }
      percentage = completed_steps * 100 / required_steps.count
      h.content_tag(:span, "#{percentage.to_i}% COMPLETE", class: 'status-indicator')
    end

    def approve_reject_buttons
      if approved?
        [unapprove_button]
      else
        [approve_button, reject_button].compact
      end
    end

    def unapprove_button
      return unless can?(:unapprove)
      h.button_to 'Unapprove', h.unapprove_event_path(@model, return: h.return_path),
                  method: :put, class: 'btn btn-primary'
    end

    def approve_button
      return unless can?(:approve)
      h.content_tag(:div, class: 'action-event-wrapper') do
        (h.button_to 'Approve', h.approve_event_path(@model, return: h.return_path),
                     method: :put, class: 'btn btn-primary', disabled: !submitted?) +
        (!submitted? ? h.content_tag(:div, '', id: 'approve-event-button', data: { message: I18n.t('instructive_messages.execute.approve') }) : '')
      end
    end

    def reject_button
      return unless can?(:reject)
      h.content_tag(:div, class: 'action-event-wrapper') do
        (h.button_to 'Reject', h.reject_event_path(@model, format: :js, return: h.return_path),
                     form: { id: 'reject-post-event' },
                     method: :put, class: 'btn btn-primary', remote: true, disabled: !submitted?) +
        (!submitted? ? h.content_tag(:div, '', id: 'reject-event-button', data: { message: I18n.t('instructive_messages.execute.reject') }) : '')
      end
    end

    def submit_button
      return unless can?(:submit)
      disabled = phases[:current_phase] == :plan || submitted? || approved? || !valid_to_submit?
      h.button_to 'Submit', h.submit_event_path(@model, format: :js, return: h.return_path),
                  class: 'btn btn-primary submit-event-data-link', method: :put,
                  remote: true, data: { disable_with: 'submitting' },
                  disabled: disabled
    end

    def guided_message(phase, step)
      guided_message_presenter.send("#{phase}_#{step[:id]}") || ''
    end

    def initial_message_js
      message, color, close = guided_message_presenter.initial_message
      return unless message && color
      "EventDetails.showMessage('#{h.j(message.html_safe)}', '#{color}', #{close});".html_safe
    end

    def submit_incomplete_message(requirements)
      return unless requirements
      I18n.translate('instructive_messages.execute.submit.fail', event_requirements: requirements)
    end

    def guided_message_presenter
      @guided_message_presenter ||= Html::EventGuidedMessagePresenter.new(@model, h)
    end
  end
end
