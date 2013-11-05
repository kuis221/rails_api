class VenuesController < FilteredController
  actions :index, :show

  helper_method :place_events
  respond_to :xlsx, only: :index

  custom_actions member: [:select_areas, :add_areas]

  def collection
    @extended_places = nil
    super
    if places = get_collection_ivar
      @extended_places ||= begin
        google_results = load_google_places
        ids = places.map{|p| p.place.place_id}
        places += google_results.reject{|gp| ids.include?(gp.id) }
        places
      end
    end
    @extended_places
  end

  def select_areas
    @areas = current_company.areas.not_in_venue(resource.place).order('name ASC')
  end

  def add_areas
    @area = current_company.areas.find(params[:area_id])
    unless resource.place.area_ids.include?(@area.id)
      resource.place.areas << @area
    end
  end

  def delete_area
    @area = current_company.areas.find(params[:area_id])
    resource.place.areas.delete(@area)
  end

  protected
    def load_google_places
      places=[]
      if params[:location].present?
        (lat,lng) = params[:location].split(',')
        places = google_places_client.spots(lat, lng, keyword: params[:q], radius: 50000)
      end
      places
    end


    def facets
      @facet_search ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :current_company_user, :location, :company_id].include?(k.to_sym)})
        facet_search = Venue.do_search(facet_params, true)

        if rows = facet_search.stats.first.rows
          max_events       = rows.select{|r| r.stat_field == 'events_is' }.first.value
          max_promo_hours  = rows.select{|r| r.stat_field == 'promo_hours_es' }.first.value
          max_impressions  = rows.select{|r| r.stat_field == 'impressions_is' }.first.value
          max_interactions = rows.select{|r| r.stat_field == 'interactions_is' }.first.value
          max_sampled      = rows.select{|r| r.stat_field == 'sampled_is' }.first.value
          max_spent        = rows.select{|r| r.stat_field == 'spent_es' }.first.value
          max_venue_score  = rows.select{|r| r.stat_field == 'venue_score_is' }.first.value

          f.push(label: "Events", name: :events, min: 0, max: max_events.to_i, selected_min: search_params[:events][:min], selected_max: search_params[:events][:max] )
          f.push(label: "Promo Hours", name: :promo_hours, min: 0, max: max_promo_hours.to_i, selected_min: search_params[:promo_hours][:min], selected_max: search_params[:promo_hours][:max] )
          f.push(label: "Impressions", name: :impressions, min: 0, max: max_impressions.to_i, selected_min: search_params[:impressions][:min], selected_max: search_params[:impressions][:max] )
          f.push(label: "Interactions", name: :interactions, min: 0, max: max_interactions.to_i, selected_min: search_params[:interactions][:min], selected_max: search_params[:interactions][:max] )
          f.push(label: "Samples", name: :sampled, min: 0, max: max_sampled.to_i, selected_min: search_params[:sampled][:min], selected_max: search_params[:sampled][:max] )
          f.push(label: "$ Spent", name: :spent, min: 0, max: max_spent.to_i, selected_min: search_params[:spent][:min], selected_max: search_params[:spent][:max] )
          f.push(label: "Venue Score", name: :venue_score, min: 0, max: max_venue_score.to_i, selected_min: search_params[:venue_score][:min], selected_max: search_params[:venue_score][:max] )

        end
        # Prices
        prices = [
            build_facet_item({label: '$', id: '1', name: :price, count: 1, ordering: 1}),
            build_facet_item({label: '$$', id: '2', name: :price, count: 1, ordering: 2}),
            build_facet_item({label: '$$$', id: '3', name: :price, count: 1, ordering: 3}),
            build_facet_item({label: '$$$$', id: '4', name: :price, count: 1, ordering: 3})
        ]
        f.push(label: "Price", items: prices )

        f.push build_locations_bucket(facet_search)
        f.push(label: "Campaigns", items: facet_search.facet(:campaigns).rows.map{|x| id, name = x.value.split('||'); build_facet_item({label: name, id: id, name: :campaign, count: x.count}) })
        f.push build_brands_bucket(facet_search.facet(:campaigns).rows)
      end
    end

    def resource
      if params[:id] =~ /^[0-9]+$/
        @place ||= Venue.find(params[:id])
      else
        @place ||= begin
          venue = Venue.new(place_id: nil, company_id: current_company.id)
          venue.place = Place.load_by_place_id(params[:id], params[:ref])
          venue
        end
      end
      @place
    end

    def google_places_client
      @google_places_client = GooglePlaces::Client.new(GOOGLE_API_KEY)
    end

    def search_params
      @search_params ||= begin
        super
        unless @search_params.has_key?(:types) && !@search_params[:types].empty?
          @search_params[:types] = %w(establishment)
        end

        [:events, :promo_hours, :impressions, :interactions, :sampled, :spent, :venue_score].each do |param|
          @search_params[param] ||= {}
          @search_params[param][:min] = 0 unless @search_params[:location].present? || @search_params[param][:min].present?
          @search_params[param][:max] = nil if @search_params[param][:max].nil? || @search_params[param][:max].empty?
        end
        @search_params
      end
    end

    def place_events
      @place_events ||= begin
          if resource.persisted?
            resource.events.scoped_by_company_id(current_company).all
          else
            []
          end
      end
    end
end
