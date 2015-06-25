# Class that performs searches in our local database (Solr) and in Google's
# api and returns the results as Hash
class CombinedSearch
  attr_accessor :params

  def initialize(params)
    @params = params
  end

  # Performs the search and returns the results
  def results
    results = solr_search
    google_place_ids = google_place_ids_from_places(results.map { |p| p[:id] })
    google_results = filter_duplicated google_search, google_place_ids
    google_results.each_with_index { |_, i|  results[i] ||= nil  }
    sort_results (results + google_results).flatten.compact.slice(0, 10)
  end

  def sort_results(rows)
    sort_index = { true => 0, false => 1 } # elements with :valid=true should go first
    if params[:location] && params[:location] =~ /.+,.+/
      add_distance_to_results(rows, params[:location])
      rows.sort_by { |a| [sort_index[a[:valid]], a[:location][:distance]] }
    else
      rows.sort! { |x, y| sort_index[x[:valid]] <=> sort_index[y[:valid]] }
    end
  end

  def add_distance_to_results(rows, location)
    lat, lon = params[:location].split(',')
    rows.each do |r|
      r[:location][:distance] =
        if r[:location] && r[:location][:latitude]
          Geocoder::Calculations.distance_between(
            [r[:location][:latitude], r[:location][:longitude]], [lat, lon])
        else
          99999
        end
    end
  end

  def solr_search
    Venue.do_search(search_params).results.map do |p|
      address = (p.formatted_address ||
                [p.city, (p.country == 'US' ? p.state : p.state_name), p.country].compact.join(', '))
      {
        value: p.name + ', ' + address,
        label: p.name + ', ' + address,
        id: p.place_id,
        location: { latitude: p.latitude, longitude: p.longitude },
        valid: true
      }
    end
  end

  def filter_duplicated(results, place_ids)
    merged_ids = Place.where.not(merged_with_place_id: nil).where(place_id: results.map{ |r| r[:id] }).pluck(:place_id)
    results.reject do |p|
      reference, id = p[:id].split('||')
      place_ids.include?(reference) || place_ids.include?(id) || merged_ids.include?(id)
    end
  end

  def google_search
    google_results = fetch_results_from_google
    return [] unless google_results && google_results['results'].present?
    google_results['results'].slice(0, 5).map do |p|
      name = p['formatted_address'].match(/\A#{Regexp.escape(p['name'])}/i) ? nil : p['name']
      label = [name, p['formatted_address'].to_s].compact.join(', ')
      { value: label, label: label, id: "#{p['reference']}||#{p['place_id']}",
       location: result_location(p), valid: valid_place_for_user?(p) }
    end
  rescue OpenURI::HTTPError => e
    Rails.logger.info "failed to load results from Google: #{e.message}"
    []
  end

  def fetch_results_from_google
    url = 'https://maps.googleapis.com/maps/api/place/textsearch/json?'\
          "key=#{GOOGLE_API_KEY}&query=#{CGI.escape(params[:q])}&sensor=false"
    JSON.parse(open(url).read)
  end

  def valid_place_for_user?(google_place)
    params[:current_company_user].nil? ||
      params[:current_company_user].allowed_to_access_place?(
        build_place_from_result(google_place))
  end

  # Returns a hash with the latitude and longitude from a result from Google's
  # API, if the result have the geometry->location value
  def result_location(p)
    return unless p.key?('geometry') && p['geometry'].key?('location')
    { latitude: p['geometry']['location']['lat'], longitude: p['geometry']['location']['lng'] }
  end

  # Returns an array with the reference and place_id from the given place ids
  def google_place_ids_from_places(ids)
    Place.where(id: ids).where.not(place_id: nil).pluck(:place_id, :reference).flatten.compact
  end

  def search_params
    params.merge per_page: 5,
                 search_address: true,
                 location: nil,
                 sorting: 'score',
                 sorting_dir: 'desc'
  end

  def build_place_from_result(result)
    if result['formatted_address'] &&
       (m = result['formatted_address'].match(/\A(.*?,?\s*(?<city>[^,]+)\s*,\s*)?(?<state>[^,]+)\s*,\s*(?<country>[^,]+)\s*\z/))
      country = m[:country]
      country = Country.all.find(-> { [country, country] }) { |c| b = Country.new(c[1]); b.alpha3 == country }[1] if country.match(/\A[A-Z]{3}\z/)
      country = Country.all.find(-> { [country, country] }) { |c| c[0].downcase == country.downcase }[1] unless country.match(/\A[A-Z]{2}\z/)
      if (country_obj = Country.new(country)) && country_obj.data
        state = m[:state]
        state.gsub!(/\s+[0-9\-]+\s*\z/, '') # Strip Zip code from stage if present
        state = country_obj.states[state]['name'] if country_obj.states.key?(state)
        if result['types'].present? && result['types'].include?('administrative_area_level_1')
          city = nil
        else
          city = find_city(m[:city], state, country)
        end
        Place.new(name: result['name'], city: city, state: state, country: country, types: result['types'])
      end
    end
  end

  def find_city(name, state, country)
    return if name.blank?
    search_name = name.downcase.gsub(/mt /, 'mount')
    city = Place.where(state: state, country: country)
           .where('? = ANY(types) AND similarity(replace(lower(name), \'mt \',\'mount \'), ?) >= 0.5', 'political', search_name).first
    city ? city.name : name
  end
end
