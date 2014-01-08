# == Schema Information
#
# Table name: places
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  reference              :string(400)
#  place_id               :string(100)
#  types                  :string(255)
#  formatted_address      :string(255)
#  latitude               :float
#  longitude              :float
#  street_number          :string(255)
#  route                  :string(255)
#  zipcode                :string(255)
#  city                   :string(255)
#  state                  :string(255)
#  country                :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  administrative_level_1 :string(255)
#  administrative_level_2 :string(255)
#  td_linx_code           :string(255)
#

require "base64"

class Place < ActiveRecord::Base
  include GoalableModel

  validates :place_id, presence: true, uniqueness: true, unless: :is_custom_place, on: :create
  validates :reference, presence: true, uniqueness: true, unless: :is_custom_place, on: :create

  validates :country, allow_nil: true, allow_blank: true,
                      inclusion: { in: proc { Country.all.map{|c| c[1]} }, message: 'is not valid' }

  # Areas-Places relationship
  has_many :events
  has_many :placeables
  has_many :venues, dependent: :destroy

  with_options through: :placeables, :source => :placeable do |place|
    place.has_many :areas, :source_type => 'Area'
    place.has_many :campaigns, :source_type => 'Campaign'
    place.has_many :users, :source_type => 'CompanyUser'
    place.has_many :teams, :source_type => 'Team'
  end

  attr_accessor :do_not_connect_to_api
  attr_accessor :is_custom_place
  before_create :fetch_place_data

  serialize :types

  def street
    "#{street_number} #{route}".strip
  end

  def country_name
    load_country.name rescue nil unless load_country.nil?
  end

  def state_name
    state || load_country.states[administrative_level_1]['name'] rescue nil if load_country and state
  end

  def continent_name
    load_country.continent if load_country
  end

  def load_country
    @the_country ||= Country.new(country) if country
  end

  def name_with_location
    [self.name, self.route, self.city, self.state_name, self.country_name].compact.uniq.join(', ')
  end

  def update_info_from_api
    fetch_place_data
    save
  end

  # First try to find comments in the app from events, then if there no enough comments in the app,
  # search for reviews from Google Places API
  def reviews(company_id)
    list_reviews = []
    if persisted?
      list_reviews = Comment.for_places(self, company_id).limit(5).all
    end
    list_reviews += spot.reviews if spot && list_reviews.length < 5
    list_reviews.slice(0, 5)
  end

  def price_level
    spot.price_level.to_i rescue 0
  end

  def formatted_phone_number
    spot.formatted_phone_number if spot
  end

  def website
    spot.website if spot
  end

  def opening_hours
    spot.opening_hours if spot
  end

  # First try to find photos in the app from events, then if there no enough photos in the app,
  # search for photos from Google Places API
  def photos(company_id)
    list_photos = []
    if persisted?
      search = AttachedAsset.do_search(place_id: self.id, company_id: company_id, asset_type: 'photo', status: 'Active', sorting: :created_at, sorting_dir: :desc, per_page: 10)
      list_photos = search.results
    end
    list_photos += spot.photos if spot && list_photos.length < 10
    list_photos.slice(0, 10)
  end

  class << self
    def load_organized(company_id, counts)
      places = find(:all)
      list = {label: :root, items: [], id: nil, path: nil}

      areas = Area.scoped_by_company_id(company_id).active

      Place.unscoped do
        places.each do |p|
          parents = [p.continent_name, p.country_name, p.state_name, p.city].compact

          areas.each{|area| area.count_events(p, parents, counts[p.id])} if counts.has_key?(p.id) && counts[p.id] > 0
          create_structure(list, parents)
        end
      end

      areas = areas.select{|a| a.events_count.present? && a.events_count > 0}

      areas.each do |area|
        p  = create_structure(list, area.common_denominators || [])
        p[:items] ||= []
        p[:items].push({label: area.name, id: area.id, count: 1, name: :area, group: 'Areas'})
      end

      {locations: simplify_list(list[:items]), areas: areas}
    end

    def encode_location(path)
      path = path.compact.join('/') if path.is_a?(Array)
      Digest::MD5.hexdigest(path.downcase)
    end

    def load_by_place_id(place_id, reference)
      Place.find_or_initialize_by_place_id({place_id: place_id, reference: reference}, without_protection: true) do |p|
        p.send(:fetch_place_data)
      end
    end

    # Returns a list of the different locations where the place belongs to, so, if the place
    # is in Los Angeles, CA, it will return:
    # ["460491fc520f4dbfcff22d1a45f6b056", "cdbe9fe33896a9afa77c66177551fa54", "e6694f45ba1b5e30c99e64ae676c2240", "e4f529bbd3bfe9699536ec957be40fa1"]
    # where
    # * "North America" ==> 460491fc520f4dbfcff22d1a45f6b056
    # * "North America/United States" ==> cdbe9fe33896a9afa77c66177551fa54
    # * "North America/United States/California"  ==> e6694f45ba1b5e30c99e64ae676c2240
    # * "North America/United States/California/Los Angeles" ==> e4f529bbd3bfe9699536ec957be40fa1
    #
    def locations_for_index(place)
      ary = political_division(place)
      ary.count.times.map { |i| encode_location(ary.slice(0, i+1)) } unless ary.nil?
    end

    def location_for_search(place)
      unless place.nil?
        return nil if place.types.present? && place.types.include?('establishment')
        return encode_location(political_division(place))
      end
    end

    def political_division(place)
      unless place.nil?
        neighborhood = place.neighborhood
        neighborhood ||= place.name if place.types.is_a?(Array) && place.types.include?('sublocality') && place.name != place.city
        [place.continent_name, place.country_name, place.state_name, place.city, neighborhood].compact if place.present?
      end
    end

    private
      def create_structure(list, parents)
        groups = ['Continents', 'Countries', 'States', 'Cities']
        p = list
        i = 1
        parents.each do |label|
          if p[:items].nil? || (c = p[:items].select{|i| i[:label] == label}.first).nil?
            location_id = Base64.strict_encode64(encode_location(parents[0..i-1]) + '||' + label)
            c = {id: location_id, name: :place, label: label, group: groups[i-1], items: nil, count: 1}
            p[:items] ||= []
            p[:items].push c
          end
          i += 1
          p = c
        end
        p
      end

      def simplify_list(items)
        if items and items.size == 1
          if items[0][:items]
            simplify_list(items[0][:items])
          else
            items
          end
        elsif items
          items.each do |item|
            item[:items] = simplify_list(item[:items])
          end
          items
        end
      end
  end


  class << self
    # Combine search results from Google API and Existing places
    def combined_search(params)
      local_results = Venue.do_search(params.merge({per_page: 5, search_address: true, sorting: 'score', sorting_dir: 'desc'})).results
      results = local_results.map do |p|
        address = (p.formatted_address || [p.city, (p.country == 'US' ? p.state : p.state_name), p.country].compact.join(', '))
        {value: p.name + ', ' + address, label: p.name + ', ' + address, id: p.place_id}
      end
      local_references = local_results.map{|p| [p.reference, p.place.place_id]}.flatten.compact
      puts local_references.inspect

      google_results = JSON.parse(open("https://maps.googleapis.com/maps/api/place/textsearch/json?key=#{GOOGLE_API_KEY}&sensor=false&query=#{URI::encode(params[:q])}").read)
      if google_results && google_results['results'].present?
        results += google_results['results'].reject{|p| local_references.include?(p['reference']) || local_references.include?(p['id']) }.map{|p| {value: p['name'] + ', ' + p['formatted_address'].to_s, label: p['name'] + ', ' + p['formatted_address'].to_s, id: "#{p['reference']}||#{p['id']}"} }
      end
      results
    end
  end

  private

    def fetch_place_data
      if reference && !do_not_connect_to_api
        self.name = spot.name
        self.latitude = spot.lat
        self.longitude = spot.lng
        self.formatted_address = spot.formatted_address
        self.types = spot.types
        sublocality = nil

        # Parse the address components
        if spot.address_components.present?
          spot.address_components.each do |component|
            if component['types'].include?('country')
              self.country = component['short_name']
            elsif component['types'].include?('administrative_area_level_1')
              self.administrative_level_1 = component['short_name']
              self.state = component['long_name']
            elsif component['types'].include?('administrative_area_level_2')
              self.administrative_level_2 = component['short_name']
            elsif component['types'].include?('locality')
              self.city = component['long_name']
            elsif component['types'].include?('postal_code')
              self.zipcode = component['long_name']
            elsif component['types'].include?('street_number')
              self.street_number = component['long_name']
            elsif component['types'].include?('route')
              self.route = component['long_name']
            elsif component['types'].include?('sublocality') || component['types'].include?('neighborhood')
              self.neighborhood = component['long_name']
            end
          end
        end

        # Sometimes the API doesn't provide the state's long_name
        if self.country == 'US' && self.state =~ /^[A-Z]{1,2}$/
          self.state = load_country.states[administrative_level_1]['name'] rescue self.state if load_country
        end

        # Make sure the city returned by Google is the correct one
        if self.city.present?
          results = client.spots(self.latitude, self.longitude, types: 'political', name: self.city, radius: 50000)
          if results.any?
            results.each do |result|
              city_spot = client.spot(result.reference)
              if city_spot.city == city_spot.name || city_spot.name == self.city
                self.city = city_spot.city if city_spot.present? && city_spot.city.present?
                break
              end
            end
          end
        end

        sublocality = self.neighborhood
        sublocality ||= self.route if types.include?('establishment')
        sublocality ||= self.zipcode if types.include?('establishment')

        # There are cases where the API doesn't give a city but a neighborhood (sublocality)
        if !self.city && !self.types.include?('administrative_area_level_2') && sublocality
          spots = client.spots(self.latitude, self.longitude, keywords: sublocality)
          spots.each do |aspot|
            s = client.spot(aspot.reference)
            if s.address_components.present?
              city = s.address_components.detect{|c| c['types'].include?('locality') }.try(:[], 'long_name')
              if city.present?
                self.city = city
                break
              end
            end
          end

          # If still there is no city... :s then assign it's own name as the city
          # Example of places with this issue:
          # West Lake, TX: client.spot('CnRoAAAATClnCR7qKsJeD5nYegW8j9BLrDI2OsM-89wiA-NO-acvlYhSYXcef09z4Dns2p92zVfCCYJPET33QkrkzKeBt9y_fVOF-UfckvjwADE-rGsj4FIBJ4-s7O88LC0Y4yOz5e8vwYy5RjmMjx-dhG0IQxIQ3RfSNWKpoqim4qMLhdGhUhoUkH8hTzQ8E7Wgv6afi0RQmYzBP2Y')
          if !self.city
            self.city = self.name
          end
        end

        self.city.strip! unless self.city.nil?
        self.state.strip! unless self.city.nil?
        self.country.strip! unless self.city.nil?
        self
      end
    end

    def spot
      @spot ||= client.spot(reference) if reference.present?
    end

    def client
      @client ||= GooglePlaces::Client.new(GOOGLE_API_KEY)
    end
end
