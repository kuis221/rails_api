module FacetsHelper

  def filter_settings_scope
    params[:apply_to] || controller_name
  end

  # Facet helper methods
  def build_facet(klass, title, name, facets)
    items = if klass.name == 'CompanyUser'
              klass.where(id: facets.map(&:value)).for_dropdown
                .map { |x| build_facet_item(label: x[0], id: x[1], name: name) }
    else
      klass.where(id: facets.map(&:value)).order(:name)
        .map { |x| build_facet_item(label: x.name, id: x.id, name: name) }
    end

    { label: title, items: items }
  end

  def build_facet_item(options)
    options[:selected] ||= params.key?(options[:name]) && ((params[options[:name]].is_a?(Array) && (params[options[:name]].include?(options[:id]) || params[options[:name]].include?(options[:id].to_s))) || (params[options[:name]] == options[:id]) || (params[options[:name]] == options[:id].to_s))
    options
  end

  def facets
    @facets ||= respond_to?("#{controller_name}_facets") ? send("#{controller_name}_facets") : []
  end

  def items_to_show(format: :boolean)
    if format == :string
      current_company_user.filter_setting_present('show_inactive_items', filter_settings_scope) ? ['active', 'inactive'] : ['active']
    else
      current_company_user.filter_setting_present('show_inactive_items', filter_settings_scope) ? [true, false] : [true]
    end
  end

  def build_brands_bucket
    brands = Brand.where('active in (?)', items_to_show).joins(:campaigns).where(campaigns: { aasm_state: 'active', id: current_company_user.accessible_campaign_ids }).for_dropdown.map do |b|
      build_facet_item(label: b[0], id: b[1], name: :brand)
    end
    { label: 'Brands', items: brands }
  end

  def build_areas_bucket
    places = current_company_user.places
    areas = current_company.areas.where('active in (?)', items_to_show).accessible_by_user(current_company_user).order(:name).to_a
    places.each do |p|
      areas += current_company.areas
               .where('active in (?)', items_to_show || [true, false])
               .where('id NOT IN (?)', areas.map(&:id) + [0]).select { |a| a.place_in_locations?(p) }
    end

    areas = areas.sort_by(&:name).map { |a| build_facet_item(label: a.name, id: a.id, count: a.events_count, name: :area) }
    { label: 'Areas', items: areas }
  end

  def build_people_bucket
    status = items_to_show

    users = Company.connection.unprepared_statement do
      ActiveRecord::Base.connection.select_all("
        #{current_company.company_users.where('company_users.active in (?)', status).select('company_users.id, users.first_name || \' \' || users.last_name as name').joins(:user).to_sql}
        ORDER BY name ASC
      ").map { |r| build_facet_item(label: r['name'], id: r['id'], name: :user, count: 1) }
    end

    teams = Company.connection.unprepared_statement do
      ActiveRecord::Base.connection.select_all("
        #{current_company.teams.where('teams.active in (?)', status).select('teams.id, teams.name').to_sql}
        ORDER BY name ASC
      ").map { |r| build_facet_item(label: r['name'], id: r['id'], name: :team, count: 1) }
    end

    people = (users + teams).sort { |a, b| a[:label] <=> b[:label] }
    { label: 'People', items: people }
  end

  def build_state_bucket
    { label: 'Active State', items: %w(Active Inactive).map { |x| build_facet_item(label: x, id: x, name: :status, count: 1) } }
  end

  def build_role_bucket
    items = current_company.roles.where('active in (?)', items_to_show).order(:name).pluck(:name, :id).map do |r|
      build_facet_item(label: r[0], id: r[1], name: :role, count: 1)
    end
    { label: 'Roles', items: items }
  end

  def build_activity_type_bucket
    items = current_company.activity_types.where('active in (?)', items_to_show).order(:name).pluck(:name, :id).map do |r|
      build_facet_item(label: r[0], id: r[1], name: :activity_type, count: 1)
    end
    { label: 'Activity Types', items: items }
  end

  def build_team_bucket
    items = current_company.teams.where('active in (?)', items_to_show).order(:name).pluck(:name, :id).map do |r|
      build_facet_item(label: r[0], id: r[1], name: :team, count: 1)
    end
    { label: 'Teams', items: items }
  end

  def build_users_bucket
    users = current_company.company_users.where('company_users.active in (?)', items_to_show)
      .joins(:user).order('2 ASC')
      .pluck('company_users.id, users.first_name || \' \' || users.last_name as name').map do |r|
      build_facet_item(label: r[1], id: r[0], name: :user, count: 1)
    end
    { label: 'Users', items: users }
  end

  def build_brand_portfolio_bucket
    items = current_company.brand_portfolios.where('active in (?)', items_to_show).order(:name).pluck(:name, :id).map do |r|
      build_facet_item(label: r[0], id: r[1], name: :brand_portfolio, count: 1)
    end
    { label: 'Brand Portfolios', items: items }
  end

  def build_status_bucket
    { label: 'Event Status', items: %w(Late Due Submitted Rejected Approved)
        .map { |x| build_facet_item(label: x, id: x, name: :event_status, count: 1) }
        .sort { |a, b| a[:label] <=> b[:label] } }
  end

  def build_campaign_bucket
    status = items_to_show(format: :string)

    items = Campaign.accessible_by_user(current_company_user).where('aasm_state in (?)', status).order(:name).pluck(:name, :id).map do |r|
      build_facet_item(label: r[0], id: r[1], name: :campaign, count: 1)
    end
    { label: 'Campaigns', items: items }
  end

  def build_custom_filters_bucket
    groups = {}
    CustomFilter.for_company_user(current_company_user).not_user_saved_filters
      .order('custom_filters.name ASC').by_type(filter_settings_scope).each do |filter|
      groups[filter.group.upcase] ||= []
      groups[filter.group.upcase].push filter
    end

    groups.map do |group, filters|
      { label: group,
        items: filters.map do |cf|
          build_facet_item(id: cf.filters + '&id=' + cf.id.to_s,
                           label: cf.name, name: :custom_filter, count: 1)
        end }
    end
  end

  def user_saved_filters(scope=nil)
    scope ||= filter_settings_scope
    items = CustomFilter.for_company_user(current_company_user).user_saved_filters
            .order('custom_filters.name ASC').by_type(scope)

    { label: CustomFilter::SAVED_FILTERS_NAME,
      items: items.map do |cf|
        build_facet_item(id: cf.filters + '&id=' + cf.id.to_s,
                         label: cf.name, name: :custom_filter, count: 1)
      end }
  end

  def build_brand_ambassadors_bucket
    users = brand_ambassadors_users.where('company_users.active in (?)', items_to_show)
      .joins(:user).order('2 ASC')
      .pluck('company_users.id, users.first_name || \' \' || users.last_name as name').map do |r|
      build_facet_item(label: r[1], id: r[0], name: :user, count: 1)
    end
    { label: 'Brand Ambassadors', items: users }
  end

  def build_tasks_status_bucket
    tasks_status = %w(Complete Incomplete Late) + (params[:scope] == 'user' ? [] : %w(Assigned Unassigned))
    { label: 'Task Status', items: tasks_status
        .map { |x| build_facet_item(label: x, id: x, name: :task_status, count: 1) } }
  end

  def brand_ambassadors_users
    @brand_ambassadors_users ||= begin
      s = current_company.company_users.active
      s = s.where(role_id: current_company.brand_ambassadors_role_ids) if current_company.brand_ambassadors_role_ids.any?
      s
    end
  end

  def build_city_bucket
    cities = current_company.brand_ambassadors_visits
      .active.where.not(city: '').reorder(:city).pluck('DISTINCT brand_ambassadors_visits.city').map do |r|
      build_facet_item(label: r, id: r, name: :city, count: 1)
    end
    { label: 'Cities', items: cities }
  end

  # Returns the facets for the events controller
  def events_facets
    @events_facets ||= Array.new.tap do |f|
      f.push build_campaign_bucket
      f.push build_brands_bucket
      f.push build_areas_bucket
      f.push build_people_bucket

      f.push build_status_bucket
      f.push build_state_bucket
      f.concat build_custom_filters_bucket
    end
  end

  def tasks_facets
    @tasks_facets ||= Array.new.tap do |f|
      # select what params should we use for the facets search
      f.push build_campaign_bucket
      f.push build_tasks_status_bucket
      f.push build_people_bucket.merge(label: 'Staff') if params[:scope] == 'teams'
      f.push build_state_bucket
      f.concat build_custom_filters_bucket
    end
  end

  # Returns the facets for the venues controller
  def venues_facets
    @facet_search ||= Array.new.tap do |f|
      # select what params should we use for the facets search
      facet_params = HashWithIndifferentAccess.new(search_params.select { |k, _v| %w(q current_company_user location company_id).include?(k) })
      facet_search = Venue.do_search(facet_params, true)

      if rows = facet_search.stats.first.rows
        max_events       = rows.find { |r| r.stat_field == 'events_count_is' }.try(:value).try(:to_i) || 1
        max_promo_hours  = rows.find { |r| r.stat_field == 'promo_hours_es' }.try(:value).try(:to_i) || 1
        max_impressions  = rows.find { |r| r.stat_field == 'impressions_is' }.try(:value).try(:to_i) || 1
        max_interactions = rows.find { |r| r.stat_field == 'interactions_is' }.try(:value).try(:to_i) || 1
        max_sampled      = rows.find { |r| r.stat_field == 'sampled_is' }.try(:value).try(:to_i) || 1
        max_spent        = rows.find { |r| r.stat_field == 'spent_es' }.try(:value).try(:to_i) || 1
        max_venue_score  = rows.find { |r| r.stat_field == 'venue_score_is' }.try(:value).try(:to_i) || 1

        f.push(label: 'Events', name: :events_count, min: 0, max: max_events > 0 ? max_events : 1, selected_min: search_params[:events_count].try(:[], :min), selected_max: search_params[:events_count].try(:[], :max))
        f.push(label: 'Impressions', name: :impressions, min: 0, max: max_impressions > 0 ? max_impressions : 1, selected_min: search_params[:impressions].try(:[], :min), selected_max: search_params[:impressions].try(:[], :max))
        f.push(label: 'Interactions', name: :interactions, min: 0, max: max_interactions > 0 ? max_interactions : 1, selected_min: search_params[:interactions].try(:[], :min), selected_max: search_params[:interactions].try(:[], :max))
        f.push(label: 'Promo Hours', name: :promo_hours, min: 0, max: max_promo_hours > 0 ? max_promo_hours : 1, selected_min: search_params[:promo_hours].try(:[], :min), selected_max: search_params[:promo_hours].try(:[], :max))
        f.push(label: 'Samples', name: :sampled, min: 0, max: max_sampled > 0 ? max_sampled : 1, selected_min: search_params[:sampled].try(:[], :min), selected_max: search_params[:sampled].try(:[], :max))
        f.push(label: 'Venue Score', name: :venue_score, min: 0, max: max_venue_score > 0 ? max_venue_score : 1, selected_min: search_params[:venue_score].try(:[], :min), selected_max: search_params[:venue_score].try(:[], :max))
        f.push(label: '$ Spent', name: :spent, min: 0, max: max_spent > 0 ? max_spent : 1, selected_min: search_params[:spent].try(:[], :min), selected_max: search_params[:spent].try(:[], :max))
      end

      # Prices
      prices = [
        build_facet_item(label: '$', id: '1', name: :price, count: 1, ordering: 1),
        build_facet_item(label: '$$', id: '2', name: :price, count: 1, ordering: 2),
        build_facet_item(label: '$$$', id: '3', name: :price, count: 1, ordering: 3),
        build_facet_item(label: '$$$$', id: '4', name: :price, count: 1, ordering: 3)
      ]
      f.push(label: 'Price', items: prices)

      f.push build_areas_bucket
      f.push build_campaign_bucket
      f.push build_brands_bucket
    end
  end

  def permitted_events_search_params
    [:start_date, :end_date, :page, :sorting, :sorting_dir, :per_page,
     campaign: [], area: [], user: [], team: [], event_status: [], brand: [], status: [],
     venue: [], role: [], brand_portfolio: [], id: [], event: []]
  end
end
