class VenuesController < FilteredController
  actions :index, :show

  helper_method :data_totals

  respond_to :xls, only: :index

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
    def permitted_params
      params.permit(venue: [:place_id, :company_id])[:venue]
    end

    def load_google_places
      places=[]
      if params[:location].present?
        (lat,lng) = params[:location].split(',')
        places = google_places_client.spots(lat, lng, keyword: params[:q], radius: 50000)
      end
      places
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

        [:events_count, :promo_hours, :impressions, :interactions, :sampled, :spent, :venue_score].each do |param|
          @search_params[param] ||= {}
          @search_params[param][:min] = nil unless @search_params[:location].present? || @search_params[param][:min].present?
          @search_params[param][:max] = nil if @search_params[param][:max].nil? || @search_params[param][:max].empty?
        end
        @search_params
      end
    end

    def data_totals
      @data_totals ||= Hash.new.tap do |totals|
        totals['events_count'] = @solr_search.stat_response['stats_fields']["events_count_is"]['sum'] rescue 0
        totals['promo_hours'] = @solr_search.stat_response['stats_fields']["promo_hours_es"]['sum'] rescue 0
        totals['spent'] = @solr_search.stat_response['stats_fields']["spent_es"]['sum'] rescue 0
      end
      @data_totals
    end
end
