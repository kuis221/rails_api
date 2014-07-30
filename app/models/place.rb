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
#  neighborhood           :string(255)
#  location_id            :integer
#  is_location            :boolean
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
  has_and_belongs_to_many :locations, autosave: true
  belongs_to :location, autosave: true

  with_options through: :placeables, source: :placeable do |place|
    place.has_many :areas, source_type: 'Area'
    place.has_many :campaigns, source_type: 'Campaign'
    place.has_many :users, source_type: 'CompanyUser'
    place.has_many :teams, source_type: 'Team'
  end

  attr_accessor :do_not_connect_to_api
  attr_accessor :is_custom_place
  before_create :fetch_place_data

  after_save :clear_cache

  before_save :update_locations

  after_commit :reindex_associated

  serialize :types

  scope :in_company, ->(company) { joins(:venues).where(venues: { company_id: company} ) }

  scope :linked_to_campaign, ->(campaign) {
    select('DISTINCT places.*')
    joins(:placeables).
    where('(placeables.placeable_type=\'Campaign\' AND placeables.placeable_id=:campaign_id) OR
      (placeables.placeable_type=\'Area\' AND placeables.placeable_id  in (
        select area_id FROM areas_campaigns where campaign_id=:campaign_id
      ))', campaign_id: campaign)
  }

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

  def name_with_location(sep=', ')
    [self.name, [self.route, self.city, self.state_name, self.country_name].compact.uniq.join(', ')].join(sep)
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

  def update_locations
    ary = Place.political_division(self)
    paths = ary.count.times.map { |i| ary.slice(0, i+1).compact.join('/').downcase }
    self.locations = paths.map{|path| Location.find_or_create_by_path(path) }
    self.location = Location.find_or_create_by_path(paths.last)
    self.is_location = (self.types.present? && (self.types & ['sublocality', 'political', 'locality', 'administrative_area_level_1', 'administrative_area_level_2', 'administrative_area_level_3', 'country', 'natural_feature']).count > 0)
    true
  end

  def location_ids
    @location_ids ||= if new_record?
      update_locations unless locations.any?
      locations.map(&:id)
    else
      locations.pluck('locations.id')
    end
  end

  class << self
    def load_by_place_id(place_id, reference)
      Place.find_or_initialize_by_place_id({place_id: place_id, reference: reference}, without_protection: true) do |p|
        p.send(:fetch_place_data)
      end
    end

    def political_division(place)
      unless place.nil?
        neighborhood = place.neighborhood
        neighborhood ||= place.name if place.types.is_a?(Array) && place.types.include?('sublocality') && place.name != place.city
        [place.continent_name, place.country_name, place.state_name, place.city, neighborhood].compact if place.present?
      end
    end

    def report_fields
      {
        name:          { title: 'Name' },
        street_number: { title: 'Street 1' },
        route:         { title: 'Street 2' },
        city:          { title: 'City' },
        state:         { title: 'State' },
        country:       { title: 'Country' },
        zipcode:       { title: 'Zip code' },
        td_linx_code:  { title: 'TD Linx Code' }
      }
    end
  end

  class << self
    # Combine search results from Google API and Existing places
    def combined_search(params)
      local_results = Venue.do_search(combined_search_params(params)).results
      results = local_results.map do |p|
        address = (p.formatted_address || [p.city, (p.country == 'US' ? p.state : p.state_name), p.country].compact.join(', '))
        {
          value: p.name + ', ' + address,
          label: p.name + ', ' + address,
          id: p.place_id,
          valid: true
        }
      end
      local_references = local_results.map{|p| [p.reference, p.place.place_id]}.flatten.compact

      valid_flag = ->(result){
        params[:current_company_user].nil? ||
        params[:current_company_user].is_admin? ||
        params[:current_company_user].allowed_to_access_place?(build_from_autocoplete_result(result))
      }

      google_results = JSON.parse(open("https://maps.googleapis.com/maps/api/place/textsearch/json?key=#{GOOGLE_API_KEY}&sensor=false&query=#{URI::encode(params[:q])}").read)
      if google_results && google_results['results'].present?
        sort_index = {true => 0, false => 1} # elements with :valid=true should go first
        results.concat(google_results['results'].
          reject{|p| local_references.include?(p['reference']) || local_references.include?(p['id']) }.
          map do |p|
            name = p['formatted_address'].match(/\A#{p['name']}/i) ? nil : p['name']
            label = [name, p['formatted_address'].to_s].compact.join(', ')
            {
              value: label,
              label: label,
              id: "#{p['reference']}||#{p['id']}",
              valid: valid_flag.call(p)
            }
          end.sort!{|x,y| sort_index[x[:valid]] <=> sort_index[y[:valid]] }.slice!(0, 10-results.count))
      end
      results
    end

    def combined_search_params(params)
      params.merge per_page: 5,
          search_address: true,
          sorting: 'score',
          sorting_dir: 'desc'
    end

    def find_tdlinx_place(binds)
      connection.select_value(
        sanitize_sql_array(["select find_tdlinx_place(:name, :street, :city, :state, :zipcode)", binds])
      ).try(:to_i)
    end

    def build_from_autocoplete_result(result)
      if result['formatted_address'] &&
         (m = result['formatted_address'].match(/\A.*?,?\s*([^,]+)\s*,\s*([^,]+)\s*,\s*([^,]+)\s*\z/))
        country = m[3]
        country = Country.all.detect(->{[country, country]}){|c| b = Country.new(c[1]); b.alpha3 == country}[1] if country.match(/\A[A-Z]{3}\z/)
        country = Country.all.detect(->{[country, country]}){|c| c[0].downcase == country.downcase}[1] unless country.match(/\A[A-Z]{2}\z/)
        if (country_obj = Country.new(country)) && country_obj.data
          state = m[2]
          state.gsub!(/\s+[0-9\-]+\s*\z/, '') # Strip Zip code from stage if present
          city = m[1]
          p "state => #{state}"
          state = country_obj.states[state]['name'] if country_obj.states.has_key?(state)
          Place.new(name: result['name'], city: city, state: state, country: country, types: result['types'])
        end
      end
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
        self.state.strip! unless self.state.nil?
        self.country.strip! unless self.country.nil?

        update_locations
        self
      end
    end

    def spot
      @spot ||= client.spot(reference) if reference.present?
    rescue GooglePlaces::NotFoundError
      @spot = false
    end

    def client
      @client ||= GooglePlaces::Client.new(GOOGLE_API_KEY)
    end

    def clear_cache
      Placeable.where(place_id: id).each do |placeable|
        placeable.update_associated_resources
      end
    end

    def reindex_associated
      Sunspot.index Venue.where(place_id: id)
      self.areas.each do |area|
        Area.update_common_denominators(area)
      end
    end
end
