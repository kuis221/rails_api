class PlacesController < FilteredController
  actions :index, :new, :create, :show
  belongs_to :area, optional: true
  respond_to :json, only: [:index]
  respond_to :js, only: [:new, :create]

  helper_method :place_events

  def create
    reference_value = params[:place][:reference]
    if reference_value and !reference_value.nil? and !reference_value.empty?
      reference, place_id = reference_value.split('||')
      @place = Place.find_or_create_by_place_id(place_id, {reference: reference})
      parent.update_attributes({place_ids: parent.place_ids + [@place.id]}, without_protection: true)
    end
  end

  def destroy
    @place = Place.find(params[:id])
    parent.places.delete(@place)
  end

  def collection
    @places ||= begin
      search = CompanyPlaceInfo.do_search(search_params)
      @collection_count = search.total
      @total_pages = search.results.total_pages
      google_results = load_google_places
      places = []
      search.each_hit_with_result do |hit, result|
        result.events = hit.stored(:events)
        result.promo_hours = hit.stored(:promo_hours)
        result.impressions = hit.stored(:impressions)
        result.interactions = hit.stored(:interactions)
        result.samples = hit.stored(:samples)
        result.spent = hit.stored(:spent)
        places.push result
      end
      ids = places.map{|p| p.place.place_id}
      places += google_results.reject{|gp| ids.include?(gp.id) }
      set_collection_ivar(places)
    end
    @places
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
        Rails.logger.debug facet_params.inspect
        facet_search = CompanyPlaceInfo.do_search(facet_params, true)

        max_events = facet_search.stats.first.rows.select{|r| r.stat_field == 'events_is' }.first.value
        max_promo_hours = facet_search.stats.first.rows.select{|r| r.stat_field == 'promo_hours_es' }.first.value
        max_impressions = facet_search.stats.first.rows.select{|r| r.stat_field == 'impressions_es' }.first.value
        max_interactions = facet_search.stats.first.rows.select{|r| r.stat_field == 'interactions_es' }.first.value
        max_samples = facet_search.stats.first.rows.select{|r| r.stat_field == 'samples_es' }.first.value
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
        f.push(label: "Samples", name: :samples, min: 0, max: max_samples.to_i, selected_min: search_params[:events][:min] )
        f.push(label: "$ Spent", name: :spent, min: 0, max: max_spent.to_i, selected_min: search_params[:events][:min] )
        f.push(label: "Price", items: prices )

      end
    end

    def resource
      if params[:id] =~ /^[0-9]+$/
        @place ||= Place.find(params[:id])
      else
        @place ||= Place.load_by_place_id(params[:id], params[:ref])
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

        [:events, :promo_hours, :impressions, :interactions, :samples, :spent].each do |param|
          @search_params[param] ||= {}
          @search_params[param][:min] = 1 unless @search_params[:location].present? || @search_params[param][:min].present?
          @search_params[param][:max] ||= nil
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
