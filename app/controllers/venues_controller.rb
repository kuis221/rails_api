class VenuesController < FilteredController
  actions :index, :show

  helper_method :place_events

  custom_actions member: [:select_areas, :add_areas]

  def collection
    @places ||= begin
      search = Venue.do_search(search_params)
      @collection_count = search.total
      @total_pages = search.results.total_pages
      google_results = load_google_places
      places = []
      search.each_hit_with_result do |hit, result|
        result.events = hit.stored(:events)
        result.promo_hours = hit.stored(:promo_hours)
        result.impressions = hit.stored(:impressions)
        result.interactions = hit.stored(:interactions)
        result.sampled = hit.stored(:sampled)
        result.spent = hit.stored(:spent)
        places.push result
      end
      ids = places.map{|p| p.place.place_id}
      places += google_results.reject{|gp| ids.include?(gp.id) }
      set_collection_ivar(places)
    end
    @places
  end

  def select_areas
  end

  def add_areas
    @area = Area.find(params[:area_id])
    unless resource.place.area_ids.include?(@area.id)
      resource.place.areas << @area
    end
  end

  def delete_area
    @area = Area.find(params[:area_id])
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
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :location, :company_id].include?(k.to_sym)})
        facet_search = Venue.do_search(facet_params, true)

        max_events = facet_search.stats.first.rows.select{|r| r.stat_field == 'events_is' }.first.value
        max_promo_hours = facet_search.stats.first.rows.select{|r| r.stat_field == 'promo_hours_es' }.first.value
        max_impressions = facet_search.stats.first.rows.select{|r| r.stat_field == 'impressions_is' }.first.value
        max_interactions = facet_search.stats.first.rows.select{|r| r.stat_field == 'interactions_is' }.first.value
        max_sampled = facet_search.stats.first.rows.select{|r| r.stat_field == 'sampled_is' }.first.value
        max_spent = facet_search.stats.first.rows.select{|r| r.stat_field == 'spent_es' }.first.value

        # Date Ranges
        prices = [
            build_facet_item({label: '$', id: '1', name: :price, count: 1, ordering: 1}),
            build_facet_item({label: '$$', id: '2', name: :price, count: 1, ordering: 2}),
            build_facet_item({label: '$$$', id: '3', name: :price, count: 1, ordering: 3}),
            build_facet_item({label: '$$$$', id: '4', name: :price, count: 1, ordering: 3})
        ]
        f.push(label: "Events", name: :events, min: 0, max: max_events.to_i, selected_min: search_params[:events][:min] )
        f.push(label: "Promo Hours", name: :promo_hours, min: 0, max: max_promo_hours.to_i, selected_min: search_params[:events][:min] )
        f.push(label: "Impressions", name: :impressions, min: 0, max: max_impressions.to_i, selected_min: search_params[:events][:min] )
        f.push(label: "Interactions", name: :interactions, min: 0, max: max_interactions.to_i, selected_min: search_params[:events][:min] )
        f.push(label: "Samples", name: :sampled, min: 0, max: max_sampled.to_i, selected_min: search_params[:events][:min] )
        f.push(label: "$ Spent", name: :spent, min: 0, max: max_spent.to_i, selected_min: search_params[:events][:min] )
        f.push(label: "Price", items: prices )

        f.push build_locations_bucket(facet_search.facet(:place).rows)
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

        [:events, :promo_hours, :impressions, :interactions, :sampled, :spent].each do |param|
          @search_params[param] ||= {}
          @search_params[param][:min] = 1 unless @search_params[:location].present? || @search_params[param][:min].present?
          @search_params[param][:max] ||= nil
        end
        Rails.logger.debug "@search_params ===> #{@search_params}"
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
