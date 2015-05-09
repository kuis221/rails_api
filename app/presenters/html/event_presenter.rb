module Html
  class EventPresenter < BasePresenter
    def event_members_name(line_separator = '<br />')
      return if @model.users.nil? && @model.teams.nil?
      members = []
      @model.users.each do |team_member|
        members.push team_member.full_name if team_member.full_name.present?
      end unless @model.users.nil?

      @model.teams.each do |team|
        members.push team.name if team.name.present?
      end unless @model.teams.nil?

      members_list = members.compact.sort.join(line_separator) unless members.compact.empty?
      members_list.html_safe if members_list.present?
    end

    def team_members
      return if @model.users.nil? && @model.teams.nil?
      teams_tags.html_safe + users_tags.html_safe
    end

    def teams_tags
      return if @model.teams.nil?
      team_list = ''
      @model.teams.each do |team|
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
      return if @model.users.nil?
      users_list = ''
      @model.users.map do |team_member|
        h.content_tag(:div, class: 'user-tag has-tooltip', data: { title: h.contact_info_tooltip(team_member).to_str, trigger: :click, container: 'body' } ) do
          h.content_tag(:div, class: 'user-type') do
            h.content_tag(:i, '', class: 'icon-user')
          end +
          h.content_tag(:span, team_member.full_name)
        end
      end.join.html_safe
    end

    def render_nav_phases
      return if @model.phases.nil?
      current_phase = @model.phases[:current_phase]
      index_phase = phases[:phases].keys.index(current_phase)
      h.content_tag(:ul, id: 'event-phases-step', class: 'unstyled phases-list') do
        @model.phases[:phases].each_with_index.map do |phase, i|
          h.content_tag(:li, class: "#{'active-phase' if phase[0] == current_phase} #{'completed' if i < index_phase}") do
            h.content_tag(:span, i + 1, class: 'phase-id') +
            h.content_tag(:b, phase[0].to_s.upcase, class: 'phase') + (
              if current_phase == phase[0]
                h.content_tag(:ul, class: 'unstyled phase-steps') do
                  phase[1].each.map do |step|
                    list_step = step[:complete] ?  h.content_tag(:i, '', class: 'icon-checked') : ''
                    list_step << h.link_to(step[:title], "#event-#{step[:id]}")
                    list_step << ' '.html_safe + h.content_tag(:span, "(optional)", class: 'optional') unless step[:required]
                    h.content_tag(:li, list_step.html_safe, class: "#{'completed' if step[:complete]}")
                  end.join.html_safe
                end
              end)
          end
        end.join.html_safe
      end
    end

    def current_step_indicator
      return if @model.phases.nil?
      phases = @model.phases
      (name, steps) = phases[:phases].find { |name, _| name == phases[:current_phase] }
      h.content_tag(:ul, class: 'switch-list unstyled') do
        steps.each.each_with_index.map do |step, i|
          h.content_tag(:li) do
            h.content_tag(:a, class: 'small no-decorate collapsed', 'aria-expanded': true, 'aria-controls': 'event-details-collapse',
              data: {toggle: 'collapse', spytarget: ( i == 0 ? '#application-body' : "#event-#{step[:id]}")}, href: '#event-details-collapse') do
              h.content_tag(:span, phases[:phases].keys.index(name) + 1, class: 'phase-id') +
              h.content_tag(:b, "#{name.to_s.upcase}: #{step[:title]}") +
              h.content_tag(:span, '', class: 'arrow')

            end
          end
        end.join.html_safe
      end
    end

    def current_phases_indicator
      return if @model.phases.nil?
      phases = @model.phases
      current_phase = phases[:current_phase]
      index_phase = phases[:phases].keys.index(current_phase)
      phases[:phases].each_with_index.map do |phase, i|
        h.content_tag(:span, class: "step #{'active' if phase[0] == current_phase} #{'completed' if i < index_phase}") do
          value_phase =  i < index_phase ? h.content_tag(:i, '', class: 'icon-checked') : i + 1
          h.content_tag(:span, value_phase, class: 'circle-step') +
          phase[0].to_s.upcase
        end
      end.join.html_safe
    end
  end
end
