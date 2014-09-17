module FacetsHelper
  def search_params
    @search_params ||= params.dup.tap do |p|  # Duplicate the params array to make some modifications
      p[:company_id] = current_company.id
      p[:current_company_user] = current_company_user
    end
  end

  def filter_settings_scope
    params[:apply_to] || controller_name
  end

  # Facet helper methods
  def build_facet(klass, title, name, facets)
    items = if klass.name == 'CompanyUser'
      klass.where(id: facets.map(&:value)).for_dropdown.
        map{|x| build_facet_item({label: x[0], id: x[1], name: name})}
    else
      klass.where(id: facets.map(&:value)).order(:name).
        map{|x| build_facet_item({label: x.name, id: x.id, name: name})}
    end

    {label: title, items: items}
  end

  def build_facet_item(options)
    options[:selected] ||= params.has_key?(options[:name]) && ((params[options[:name]].is_a?(Array) and (params[options[:name]].include?(options[:id]) || params[options[:name]].include?(options[:id].to_s))) || (params[options[:name]] == options[:id]) || (params[options[:name]] == options[:id].to_s))
    options
  end

  def facets
    @facets ||= respond_to?("#{controller_name}_facets") ? send("#{controller_name}_facets") : []
  end

  def build_brands_bucket
    status = current_company_user.filter_settings_for('brands', filter_settings_scope)
    brands = Brand.where("active in (?)", status).joins(:campaigns).where(campaigns: {aasm_state: 'active', id: current_company_user.accessible_campaign_ids}).for_dropdown.map do |b|
      build_facet_item({label: b[0], id: b[1], name: :brand})
    end
    {label: 'Brands', items: brands}
  end

  def build_areas_bucket
    status = current_company_user.filter_settings_for('areas', filter_settings_scope)

    places = current_company_user.places
    areas = current_company.areas.where("active in (?)", status).accessible_by_user(current_company_user).order(:name).all

    places.each do |p|
      areas = (areas + Area.where(company_id: current_company.id).where("active in (?)", status || [true, false]).where('id NOT IN (?)', areas.map(&:id)+[0]).select{|a| a.place_in_locations?(p) })
    end

    areas = areas.sort_by(&:name).map{|a| build_facet_item({label: a.name, id: a.id, count: a.events_count, name: :area}) }
    {label: 'Areas', items: areas}
  end

  def build_people_bucket
    users_status = current_company_user.filter_settings_for('users', filter_settings_scope)
    teams_status = current_company_user.filter_settings_for('teams', filter_settings_scope)

    users = Company.connection.unprepared_statement do
      ActiveRecord::Base.connection.select_all("
        #{current_company.company_users.where("company_users.active in (?)", users_status).select('company_users.id, users.first_name || \' \' || users.last_name as name').joins(:user).to_sql}
        ORDER BY name ASC
      ").map{|r| build_facet_item({label: r['name'], id: r['id'], name: :user, count: 1}) }
    end

    teams = Company.connection.unprepared_statement do
      ActiveRecord::Base.connection.select_all("
        #{current_company.teams.where("teams.active in (?)", teams_status).select('teams.id, teams.name').to_sql}
        ORDER BY name ASC
      ").map{|r| build_facet_item({label: r['name'], id: r['id'], name: :team, count: 1}) }
    end

    people = (users + teams).sort{ |a, b| a[:label] <=> b[:label] }
    {label: 'People', items: people}
  end

  def build_state_bucket
    {label: 'Active State', items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) }}
  end

  def build_role_bucket
    status = current_company_user.filter_settings_for('roles', filter_settings_scope)
    items = current_company.roles.where("active in (?)", status).order(:name).pluck(:name, :id).map do |r|
      build_facet_item({label: r[0], id: r[1], name: :role, count: 1})
    end
    {label: "Roles", items: items}
  end

  def build_team_bucket
    status = current_company_user.filter_settings_for('teams', filter_settings_scope)
    items = current_company.teams.where("active in (?)", status).order(:name).pluck(:name, :id).map do |r|
      build_facet_item({label: r[0], id: r[1], name: :team, count: 1})
    end
    {label: "Teams", items: items}
  end

  def build_users_bucket
    status = current_company_user.filter_settings_for('users', filter_settings_scope)
    users = current_company.company_users.where("company_users.active in (?)", status).
      joins(:user).order('2 ASC').
      pluck('company_users.id, users.first_name || \' \' || users.last_name as name').map do |r|
        build_facet_item({label: r[1], id: r[0], name: :user, count: 1})
    end
    {label: 'Users', items: users}
  end

  def build_brand_portfolio_bucket
    status = current_company_user.filter_settings_for('brand_portfolios', filter_settings_scope)
    items = current_company.brand_portfolios.where("active in (?)", status).order(:name).pluck(:name, :id).map do |r|
      build_facet_item({label: r[0], id: r[1], name: :brand_portfolio, count: 1})
    end
    {label: "Brand Portfolios", items: items}
  end

  def build_status_bucket
    {label: 'Event Status', items: ['Late', 'Due', 'Submitted', 'Rejected', 'Approved'].
        map{|x| build_facet_item({label: x, id: x, name: :event_status, count: 1}) }.
        sort{ |a, b| a[:label] <=> b[:label] }}
  end

  def build_campaign_bucket
    status = current_company_user.filter_settings_for('campaigns', filter_settings_scope, true)
    items = Campaign.accessible_by_user(current_company_user).where("aasm_state in (?)", status).order(:name).pluck(:name, :id).map do |r|
      build_facet_item({label: r[0], id: r[1], name: :campaign, count: 1})
    end
    Campaign.accessible_by_user(current_company_user).where("aasm_state in (?)", status).order(:name).inspect
    {label: 'Campaigns', items: items}
  end

  def build_custom_filters_bucket
    items = current_company_user.custom_filters.by_type(filter_settings_scope).map{|cf| build_facet_item({id: cf.filters+'&id='+cf.id.to_s, label: cf.name, name: :custom_filter, count: 1}) }
    {label: "Saved Filters", items: items}
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
      f.push build_custom_filters_bucket
    end
  end

  # Returns the facets for the venues controller
  def venues_facets
    @facet_search ||= Array.new.tap do |f|
      # select what params should we use for the facets search
      facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| %w(q current_company_user location company_id).include?(k)})
      facet_search = Venue.do_search(facet_params, true)

      if rows = facet_search.stats.first.rows
        max_events       = rows.detect{|r| r.stat_field == 'events_count_is' }.try(:value).try(:to_i) || 1
        max_promo_hours  = rows.detect{|r| r.stat_field == 'promo_hours_es' }.try(:value).try(:to_i) || 1
        max_impressions  = rows.detect{|r| r.stat_field == 'impressions_is' }.try(:value).try(:to_i) || 1
        max_interactions = rows.detect{|r| r.stat_field == 'interactions_is' }.try(:value).try(:to_i) || 1
        max_sampled      = rows.detect{|r| r.stat_field == 'sampled_is' }.try(:value).try(:to_i) || 1
        max_spent        = rows.detect{|r| r.stat_field == 'spent_es' }.try(:value).try(:to_i) || 1
        max_venue_score  = rows.detect{|r| r.stat_field == 'venue_score_is' }.try(:value).try(:to_i) || 1

        f.push(label: "Events", name: :events_count, min: 0, max: max_events > 0 ? max_events : 1, selected_min: search_params[:events_count].try(:[],:min), selected_max: search_params[:events_count].try(:[],:max) )
        f.push(label: "Impressions", name: :impressions, min: 0, max: max_impressions > 0 ? max_impressions : 1, selected_min: search_params[:impressions].try(:[],:min), selected_max: search_params[:impressions].try(:[],:max) )
        f.push(label: "Interactions", name: :interactions, min: 0, max: max_interactions > 0 ? max_interactions : 1, selected_min: search_params[:interactions].try(:[],:min), selected_max: search_params[:interactions].try(:[],:max) )
        f.push(label: "Promo Hours", name: :promo_hours, min: 0, max: max_promo_hours > 0 ? max_promo_hours : 1, selected_min: search_params[:promo_hours].try(:[],:min), selected_max: search_params[:promo_hours].try(:[],:max) )
        f.push(label: "Samples", name: :sampled, min: 0, max: max_sampled > 0 ? max_sampled : 1 , selected_min: search_params[:sampled].try(:[],:min), selected_max: search_params[:sampled].try(:[],:max) )
        f.push(label: "Venue Score", name: :venue_score, min: 0, max: max_venue_score > 0 ? max_venue_score : 1, selected_min: search_params[:venue_score].try(:[],:min), selected_max: search_params[:venue_score].try(:[],:max) )
        f.push(label: "$ Spent", name: :spent, min: 0, max: max_spent > 0 ? max_spent : 1, selected_min: search_params[:spent].try(:[],:min), selected_max: search_params[:spent].try(:[],:max) )
      end

      # Prices
      prices = [
        build_facet_item({label: '$', id: '1', name: :price, count: 1, ordering: 1}),
        build_facet_item({label: '$$', id: '2', name: :price, count: 1, ordering: 2}),
        build_facet_item({label: '$$$', id: '3', name: :price, count: 1, ordering: 3}),
        build_facet_item({label: '$$$$', id: '4', name: :price, count: 1, ordering: 3})
      ]
      f.push(label: "Price", items: prices )

      f.push build_areas_bucket
      #f.push(label: "Campaigns", items: facet_search.facet(:campaigns).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, name: :campaign, count: x.count}) })
      f.push build_campaign_bucket
      f.push build_brands_bucket
    end
  end

end