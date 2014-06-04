module FacetsHelper
  def search_params
    @search_params ||= params.dup.tap do |p|  # Duplicate the params array to make some modifications
      p[:company_id] = current_company.id
      p[:current_company_user] = current_company_user
    end
  end

  # Facet helper methods
  def build_facet(klass, title, name, facets)
    items = if klass.name == 'CompanyUser'
      klass.where(id: facets.map(&:value)).
        for_dropdown.
        map{|x| build_facet_item({label: x[0], id: x[1], name: x[0]})}
    else
      klass.where(id: facets.map(&:value)).
        order(:name).
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
    brands = Brand.joins(:campaigns).where(campaigns: {aasm_state: 'active', id: current_company_user.accessible_campaign_ids}).
        for_dropdown.map do |b|
      build_facet_item({label: b[0], id: b[1], name: :brand})
    end
    {label: 'Brands', items: brands}
  end

  def build_areas_bucket(search)
    places = current_company_user.places
    list = {label: :root, items: [], id: nil, path: nil}

    areas = current_company.areas.accessible_by_user(current_company_user).order(:name).active.all
    places.each do |p|
      areas = (areas + Area.where(company_id: current_company.id).where('id NOT IN (?)', areas.map(&:id)+[0]).select{|a| a.place_in_locations?(p) })
    end

    areas = areas.sort_by(&:name).map{|a| build_facet_item({label: a.name, id: a.id, count: a.events_count, name: :area}) }
    {label: 'Areas', items: areas}
  end

  def build_people_bucket(facet_search)
    users = build_facet(CompanyUser, 'User', :user, facet_search.facet(:user_ids).rows)[:items]
    teams = build_facet(Team, 'Team', :team, facet_search.facet(:team_ids).rows)[:items]
    people = (users + teams).sort{ |a, b| a[:label] <=> b[:label] }
    {label: 'People', items: people }
  end

  def build_state_bucket(facet_search)
    counters = Hash[facet_search.facet(:status).rows.map{|r| [r.value.to_s.capitalize, r.count]}]
    {label: 'Active State', items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: counters.try(:[], x) || 0}) }}
  end

  def build_status_bucket(facet_search)
    counters = Hash[facet_search.facet(:status).rows.map{|r| [r.value.to_s.capitalize, r.count]}]
    {label: 'Event Status', items: ['Late', 'Due', 'Submitted', 'Rejected', 'Approved'].
        map{|x| build_facet_item({label: x, id: x, name: :event_status, count: counters.try(:[], x) || 0}) }.
        sort{ |a, b| a[:label] <=> b[:label] }}
  end

  def build_campaign_bucket
    items = Campaign.accessible_by_user(current_company_user).order(:name).for_dropdown.map do |r|
      build_facet_item({label: r[0], id: r[1], name: :campaign, count: 1})
    end
    { label: 'Campaigns', items: items }
  end

  # Returns the facets for the events controller
  def events_facets
    @events_facets ||= Array.new.tap do |f|
      # select what params should we use for the facets search
      facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| %w(company_id current_company_user with_event_data_only with_surveys_only).include?(k)})
      facet_search = resource_class.do_search(facet_params, true)

      f.push build_campaign_bucket
      f.push build_brands_bucket
      f.push build_areas_bucket( facet_search )
      f.push build_people_bucket( facet_search )

      f.push build_status_bucket( facet_search )
      f.push build_state_bucket( facet_search )
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

      f.push build_areas_bucket(facet_search)
      #f.push(label: "Campaigns", items: facet_search.facet(:campaigns).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, name: :campaign, count: x.count}) })
      f.push build_campaign_bucket
      f.push build_brands_bucket
    end
  end

end