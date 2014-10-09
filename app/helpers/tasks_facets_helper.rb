module TasksFacetsHelper
  # Returns the facets for the tasks controller
  def tasks_facets
    @facets ||= Array.new.tap do |f|
      # select what params should we use for the facets search

      f.push build_facet(Campaign, 'Campaigns', :campaign, facet_search.facet(:campaign_id).rows)
      f.push build_status_bucket(facet_search)
      if is_my_teams_view?
        users_count = Hash[facet_search.facet(:company_user_id).rows.map { |x| [x.value, x.count] }]
        users = current_company.company_users.includes(:user).where(id: facet_search.facet(:company_user_id).rows.map(&:value))
        users = users.map { |x|  build_facet_item(label: x.full_name, id: x.id, name: :user, count: users_count[x.id]) }
        teams = current_company.teams.joins(:users).where(company_users: { id: users_count.keys }).group('teams.id')
        teams = teams.map do |team|
          user_ids = team.user_ids
          build_facet_item(label: team.name, id: team.id, name: :team, count: user_ids.map { |id| users_count.key?(id) ? users_count[id] : 0 }.sum)
        end
        people = (users + teams).sort { |a, b| b[:label] <=> a[:label] }
        f.push(label: 'Staff', items: people)
      end
      f.push build_active_bucket(facet_search)
    end
  end

  def status_counters
    @status_counters ||= Hash.new.tap do |counters|
      counters['unassigned'] = 0
      counters['incomplete'] = 0
      counters['late'] = count_late_tasks
      facet_search.facet(:status).rows.map { |x| counters[x.value.to_s] = x.count } unless facet_search.facet(:status).nil?
    end
    @status_counters
  end

  def facet_search
    @facet_search ||= begin
      p = HashWithIndifferentAccess.new(facet_params)
      resource_class.do_search(p, true)
    end
  end

  def count_late_tasks
    @count_late_tasks ||= begin
      count_params = HashWithIndifferentAccess.new(facet_params.merge(late: true))
      search = resource_class.do_search(count_params, true)
      search.total
    end
  end

  def facet_params
    search_params.select { |k, _v| %w(q current_company_user start_date end_date user company_id event_id not_assigned_to team_members status).include?(k) }
  end

  def is_my_teams_view?
    params[:scope] == 'teams'
  end

  def is_my_tasks_view?
    params[:scope] == 'user'
  end

  def build_status_bucket(facet_search)
    tasks_status = %w(Complete Incomplete Late) + (is_my_tasks_view? ? [] : %w(Assigned Unassigned))
    counters = Hash[facet_search.facet(:status).rows.map { |r| [r.value.to_s.capitalize, r.count] }]
    { label: 'Task Status', items: tasks_status
        .map { |x| build_facet_item(label: x, id: x, name: :task_status, count: counters.try(:[], x) || 0) } }
  end

  def build_active_bucket(facet_search)
    tasks_status = %w(Active Inactive)
    counters = Hash[facet_search.facet(:status).rows.map { |r| [r.value.to_s.capitalize, r.count] }]
    { label: 'Active State', items: tasks_status
        .map { |x| build_facet_item(label: x, id: x, name: :status, count: counters.try(:[], x) || 0) } }
  end
end
