class VenuesController < FilteredController
  actions :index, :show

  helper_method :data_totals, :venue_activities

  prepend_before_action :create_venue_from_google_api, only: :show

  respond_to :xls, :pdf, only: :index

  custom_actions member: [:select_areas, :add_areas]

  def collection
    @extended_places ||= (super || []).tap do |places|
      ids = places.map { |p| p.place.place_id }
      google_results = load_google_places.reject { |gp| ids.include?(gp.id) }
      @collection_count = @collection_count.to_i + google_results.count
      places.concat google_results
    end
  end

  def select_areas
    @areas = current_company.areas.not_in_venue(resource.place).order('name ASC')
  end

  def add_areas
    @area = current_company.areas.find(params[:area_id])
    resource.place.areas << @area unless resource.place.area_ids.include?(@area.id)
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
    return [] unless params[:location].present? && params[:q].present?
    (lat, lng) = params[:location].split(',')
    google_places_client.spots(lat, lng, keyword: params[:q], radius: 50_000)
  rescue
    []
  end

  def create_venue_from_google_api
    return if params[:id] =~ /\A[0-9]+\z/
    place = Place.load_by_place_id(params[:id], params[:ref])
    fail ActiveRecord::RecordNotFound unless place
    place.save unless place.persisted?
    venue = current_company.venues.find_or_create_by(place_id: place.id)
    redirect_to venue_path(id: venue.id, return: return_path)
  end

  def google_places_client
    @google_places_client = GooglePlaces::Client.new(GOOGLE_API_KEY)
  end

  def search_params
    @search_params || (super.tap do |p|
      p[:types] = %w(establishment) unless p.key?(:types) && !p[:types].empty?
      # Do not filter by user settigns because we are not filtering google results
      # anyway...
      p[:current_company_user] = nil
      p[:search_address] = true

      [:events_count, :promo_hours, :impressions, :interactions, :sampled, :spent, :venue_score].each do |param|
        p[param] ||= {}
        p[param][:min] = nil unless p[:location].present? || p[param][:min].present?
        p[param][:max] = nil if p[param][:max].nil? || p[param][:max].empty?
      end
    end)
  end

  def data_totals
    @data_totals ||= Hash.new.tap do |totals|
      totals['events_count'] = collection_search.stat_response['stats_fields']['events_count_is']['sum'] rescue 0
      totals['promo_hours'] = collection_search.stat_response['stats_fields']['promo_hours_es']['sum'] rescue 0
      totals['spent'] = collection_search.stat_response['stats_fields']['spent_es']['sum'] rescue 0
    end
  end

  def permitted_search_params
    [:location, :q, :page, :sorting, :sorting_dir, :per_page, :start_date, :end_date,
     events_count: [:min, :max], promo_hours: [:min, :max], impressions: [:min, :max],
     interactions: [:min, :max], sampled: [:min, :max], spent: [:min, :max],
     venue_score: [:min, :max], price: [], area: [], campaign: [], brand: []]
  end
end
