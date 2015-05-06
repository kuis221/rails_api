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
      p "DDDDDDDDDDDDDDDDDDDDDDDDDDDDd"
      @model.
      e =''
    end
  end
end