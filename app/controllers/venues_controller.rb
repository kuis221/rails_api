class VenuesController < FilteredController
  actions :index, :show

  helper_method :data_totals, :venue_activities

  prepend_before_action :create_venue_from_google_api, only: :show

  respond_to :xls, :pdf, only: :index

  custom_actions member: [:select_areas, :add_areas]

  before_action :redirect_to_merged_venue, only: [:show]

  def collection
    @extended_places ||= (super || []).tap do |places|
      ids = places.map { |p| p.place.place_id }
      google_results = load_google_places.reject { |gp| ids.include?(gp.place_id) }
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
    spots = google_places_client.spots(lat, lng, keyword: params[:q], radius: 50_000)
    return [] if spots.empty?
    merged_ids = Place.where.not(merged_with_place_id: nil)
                  .joins('LEFT JOIN places nmp ON nmp.merged_with_place_id IS NULL AND nmp.place_id=places.place_id')
                  .where(place_id: spots.map{ |s| s.place_id })
                  .where('nmp.id is null')
                  .pluck(:place_id)
    spots.reject { |s| merged_ids.include?(s.place_id) }
  rescue => e
    puts "Search in google places failed with: #{e.message}"
    puts e.backtrace.inspect
    []
  end

  def create_venue_from_google_api
    return if current_user.nil?
    return if params[:id] =~ /\A[0-9]+\z/
    place = Place.load_by_place_id(params[:id], params[:ref])
    place = Place.find(place.merged_with_place_id) if place.present? && place.merged_with_place_id.present?
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
      if p[:q].present?
        p[:sorting] = :score
        p[:sorting_dir] = :asc
      end

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
    [:location, :q, :page, :sorting, :sorting_dir, :per_page, start_date: [], end_date: [],
     events_count: [:min, :max], promo_hours: [:min, :max], impressions: [:min, :max],
     interactions: [:min, :max], sampled: [:min, :max], spent: [:min, :max],
     venue_score: [:min, :max], price: [], area: [], campaign: [], brand: []]
  end

  def redirect_to_merged_venue
    return if resource.merged_with_place_id.blank?
    redirect_to venue_path(Venue.find_or_create_by(
      company_id: resource.company_id,
      place_id: resource.merged_with_place_id))
  end
end
