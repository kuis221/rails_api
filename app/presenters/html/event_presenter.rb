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

    def event_member_tag
      return if @model.users.nil? && @model.teams.nil?
      render_teams_tag.html_safe + render_users_tag.html_safe
    end

    def render_teams_tag
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

    def render_users_tag
      return if @model.users.nil?
      users_list = ''
      @model.users.each do |team_member|
        users_list = h.content_tag(:div, class: 'user-tag') do
          h.content_tag(:div, class: 'user-type') do
            h.content_tag(:i, '', class: 'icon-user')
          end +
          h.content_tag(:span, team_member.full_name)
        end.html_safe
      end
      users_list
    end

    def render_nav_phases
      return if @model.phases.nil?
      current_phase = @model.phases[:current_phase]
      phases_list = h.content_tag(:ul, class: 'unstyled phases-list') do
        @model.phases[:phases].each_with_index.map do |phase, i|
          h.content_tag(:li, class: "#{'active-phase' if phase[0] == current_phase}") do
            h.content_tag(:span, i + 1, class: 'phase-id') +
            h.content_tag(:b, phase[0].to_s.upcase, class: 'phase') +
            h.content_tag(:ul, class: 'unstyled phase-steps') do
              phase[1].each.map do |step|
                list_step = h.content_tag(:i, '', class: 'icon-checked') if step[:complete] ||= ''
                list_step << step[:title]
                h.content_tag(:li, list_step)
              end.join.html_safe
            end
          end
        end.join.html_safe
      end
      phases_list
    end

    def render_nav_too
      return if @model.phases.nil?
      current_phase = @model.phases[:current_phase]
      phases_list = h.content_tag(:ul, class: 'switch-list unstyled') do
        active = true
        @model.phases[:phases].each_with_index.map do |phase, i|
          phase[1].each.map do |step|
            h.content_tag(:li, class: "#{'active' if active}") do
              phase_step = h.content_tag(:a, class: 'small no-decorate', 'aria-expanded': true, 'aria-controls': 'collapseOne',
                data: {parent: '#accordion', toggle: 'collapse'}, href: '#collapseOne') do
                h.content_tag(:span, i + 1, class: 'phase-id') +
                h.content_tag(:b, "#{phase[0].to_s.upcase}: #{step[:title]}") +
                h.content_tag(:i, '', class: 'icon-arrow-up')
              end
              active = false
              phase_step
            end
          end.join.html_safe
        end.join.html_safe
      end
      phases_list
    end
  end
end