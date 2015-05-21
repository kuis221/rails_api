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
    sort_index = { true => 0, false => 1 } # elements with :valid=true should go first
    google_results.each_with_index { |_, i|  results[i] ||= nil  }
    results.zip(google_results.sort! { |x, y| sort_index[x[:valid]] <=> sort_index[y[:valid]] }).flatten.compact.slice(0, 5)
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
    merged_ids = Place.where.not(merged_with_place_id: nil).where(place_id: results.map{ |r| r['place_id'] }).pluck(:place_id)
    results.reject do |p|
      place_ids.include?(p['reference']) || place_ids.include?(p['place_id']) ||
      merged_ids.include?(p['place_id'])
    end
  end

  def google_search
    google_results = JSON.parse(open("https://maps.googleapis.com/maps/api/place/textsearch/json?key=#{GOOGLE_API_KEY}&sensor=false&query=#{CGI.escape(params[:q])}").read)
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
                 sorting: 'score',
                 sorting_dir: 'desc'
  end

  def build_place_from_result(result)
    if result['formatted_address'] &&
       (m = result['formatted_address'].match(/\A.*?,?\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*\z/))
      country = m[3]
      country = Country.all.find(-> { [country, country] }) { |c| b = Country.new(c[1]); b.alpha3 == country }[1] if country.match(/\A[A-Z]{3}\z/)
      country = Country.all.find(-> { [country, country] }) { |c| c[0].downcase == country.downcase }[1] unless country.match(/\A[A-Z]{2}\z/)
      if (country_obj = Country.new(country)) && country_obj.data
        state = m[2]
        state.gsub!(/\s+[0-9\-]+\s*\z/, '') # Strip Zip code from stage if present
        city = m[1]
        state = country_obj.states[state]['name'] if country_obj.states.key?(state)
        Place.new(name: result['name'], city: city, state: state, country: country, types: result['types'])
      end
    end
  end
end
