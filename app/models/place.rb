# == Schema Information
#
# Table name: places
#
#  id                     :integer          not null, primary key
#  name                   :string(255)
#  reference              :string(400)
#  place_id               :string(200)
#  types_old              :string(255)
#  formatted_address      :string(255)
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
#  location_id            :integer
#  is_location            :boolean
#  price_level            :integer
#  phone_number           :string(255)
#  neighborhoods          :string(255)      is an Array
#  lonlat                 :spatial          point, 4326
#  td_linx_confidence     :integer
#  merged_with_place_id   :integer
#  types                  :string(255)      is an Array
#

require 'base64'

class Place < ActiveRecord::Base
  include GoalableModel

  VALID_GOOGLE_TYPES = I18n.translate('venue_types').keys.map(&:to_s)

  ADDITIONAL_GOOGLE_TYPES = %w(
    administrative_area_level_1 administrative_area_level_2
    administrative_area_level_3 administrative_area_level_4 administrative_area_level_5
    colloquial_area country floor geocode intersection locality natural_feature neighborhood
    political point_of_interest post_box postal_code postal_code_prefix postal_code_suffix
    postal_town premise room route street_address street_number sublocality
    sublocality_level_4 sublocality_level_5 sublocality_level_3 sublocality_level_2
    sublocality_level_1 subpremise transit_station)

  validates :place_id, presence: true, uniqueness: true, unless: :is_custom_place, on: :create
  validates :reference, presence: true, uniqueness: true, unless: :is_custom_place, on: :create

  validates :country, allow_nil: true, allow_blank: true,
                      inclusion: { in: proc { Country.all.map { |c| c[1] } }, message: 'is not valid' }

  # Areas-Places relationship
  has_many :events
  has_many :placeables
  has_many :venues, inverse_of: :place, dependent: :destroy
  has_and_belongs_to_many :locations, autosave: true
  belongs_to :location, autosave: true

  # By default, use the GEOS implementation for spatial columns.
  self.rgeo_factory_generator = RGeo::Geos.factory_generator

  # But use a geographic implementation for the :lonlat column.
  set_rgeo_factory_for_column(:lonlat, RGeo::Geographic.spherical_factory(:srid => 4326))

  with_options through: :placeables, source: :placeable do |place|
    place.has_many :areas, source_type: 'Area'
    place.has_many :campaigns, source_type: 'Campaign'
    place.has_many :users, source_type: 'CompanyUser'
    place.has_many :teams, source_type: 'Team'
  end

  attr_accessor :do_not_connect_to_api
  attr_accessor :is_custom_place

  before_create :set_lat_lng

  before_validation :fetch_place_data, on: :create

  after_save :clear_cache

  before_save :update_locations

  validate :valid_types?, on: :create

  after_commit :reindex_associated
  scope :accessible_by_user, ->(user) { in_company(user.company_id) }
  scope :in_company, ->(company) { joins(:venues).where(venues: { company_id: company }) }
  scope :filters_between_dates, ->(start_date, end_date) { where(venues: { created_at: DateTime.parse(start_date)..DateTime.parse(end_date)})}

  accepts_nested_attributes_for :venues

  def self.linked_to_campaign(campaign)
    select('DISTINCT places.*')
      .joins(:placeables)
      .where('(placeables.placeable_type=\'Campaign\' AND placeables.placeable_id=:campaign_id) OR '\
             '(placeables.placeable_type=\'Area\' AND placeables.placeable_id  in ('\
             ' select area_id FROM areas_campaigns where campaign_id=:campaign_id'\
             '))', campaign_id: campaign)
  end

  def self.in_areas(areas)
    subquery = Place.unscoped.select('DISTINCT places.location_id')
               .joins(:placeables).where(placeables: { placeable_type: 'Area', placeable_id: areas }, is_location: true)
               .to_sql
    place_query = "select place_id FROM locations_places INNER JOIN (#{subquery})"\
                  ' locations on locations.location_id=locations_places.location_id'
    area_query = Placeable.select('place_id')
                 .where(placeable_type: 'Area', placeable_id: areas + [0]).to_sql
    joins("INNER JOIN (#{area_query} UNION #{place_query}) areas_places ON places.id=areas_places.place_id")
  end

  def self.in_campaign_areas(campaign, areas)
    subquery = Place.connection.unprepared_statement do
      Place.select('DISTINCT places.location_id, areas_campaigns.area_id')
      .joins(:placeables)
      .where(placeables: { placeable_type: 'Area', placeable_id: areas + [0] }, is_location: true)
      .joins('INNER JOIN areas_campaigns
                ON areas_campaigns.campaign_id=' + campaign.id.to_s + ' AND
                areas_campaigns.area_id=placeables.placeable_id')
      .where('NOT (places.id = ANY (areas_campaigns.exclusions))').to_sql
    end

    subquery += ' UNION ' + Place.connection.unprepared_statement do
      Place.select('DISTINCT(places.location_id), areas_campaigns.area_id')
      .joins('INNER JOIN areas_campaigns ON places.id = ANY (areas_campaigns.inclusions)')
      .where(is_location: true, areas_campaigns: { area_id: areas + [0], campaign_id: campaign.id }).to_sql
    end

    place_query = "select place_id, locations.area_id FROM locations_places INNER JOIN (#{subquery})"\
                  ' locations ON locations.location_id=locations_places.location_id'
    area_query = Placeable.select('place_id, placeable_id area_id').where(placeable_type: 'Area', placeable_id: areas)
                 .joins("INNER JOIN areas_campaigns ON areas_campaigns.campaign_id=#{campaign.id} "\
                        'AND areas_campaigns.area_id=placeables.placeable_id')
                 .where('NOT (place_id = ANY (areas_campaigns.exclusions))').to_sql

    joins("INNER JOIN (#{area_query} UNION #{place_query}) areas_places ON places.id=areas_places.place_id")
  end

  def self.in_campaign_scope(campaign)
    areas = campaign.areas.pluck(:id) + [0]

    # Places that are inside the areas scope excluding the ones in the exclusions list
    subquery = Place.connection.unprepared_statement do
      Place.select('DISTINCT places.location_id')
      .joins(:placeables)
      .where(placeables: { placeable_type: 'Area', placeable_id: areas }, is_location: true)
      .joins('INNER JOIN areas_campaigns
                ON areas_campaigns.campaign_id=' + campaign.id.to_s + ' AND
                areas_campaigns.area_id=placeables.placeable_id')
      .where('NOT (places.id = ANY (areas_campaigns.exclusions))').to_sql
    end

    # Places that are inside the inclusions lists
    subquery += ' UNION ' + Place.connection.unprepared_statement do
      Place.select('DISTINCT(places.location_id)')
      .joins('INNER JOIN areas_campaigns ON places.id = ANY (areas_campaigns.inclusions)')
      .where(is_location: true, areas_campaigns: { area_id: areas, campaign_id: campaign.id }).to_sql
    end

    # Places that are inside  places directly assigned to the campaign
    subquery += ' UNION ' + Place.connection.unprepared_statement do
      campaign.places.where(is_location: true).select('DISTINCT(places.location_id)').to_sql
    end

    place_query = "select place_id FROM locations_places INNER JOIN (#{subquery})"\
                  ' locations ON locations.location_id=locations_places.location_id'
    area_query = Placeable.select('place_id').where(placeable_type: 'Area', placeable_id: areas)
                 .joins("INNER JOIN areas_campaigns ON areas_campaigns.campaign_id=#{campaign.id} "\
                        'AND areas_campaigns.area_id=placeables.placeable_id')
                 .where('NOT (place_id = ANY (areas_campaigns.exclusions))').to_sql

    joins("INNER JOIN (#{area_query} UNION #{place_query}) areas_places ON places.id=areas_places.place_id")
  end

  def street
    "#{street_number} #{route}".strip
  end

  def country_name
    load_country.name rescue nil unless load_country.nil?
  end

  def state_name
    state || load_country.states[administrative_level_1]['name'] rescue state if load_country && state
  end

  def state_code
    return unless state && load_country
    load_country.states.find { |_, info| info['name'] == state }[0] rescue state
  end

  def continent_name
    load_country.continent if load_country
  end

  def load_country
    @the_country ||= Country.new(country) if country
  end

  def name_with_location(sep = ', ')
    [name, [route, city, state_name, country_name].compact.uniq.join(', ')].join(sep)
  end

  def update_info_from_api
    fetch_place_data
    save
  end

  def country?
    types.include?('country')
  end

  def state?
    types.include?('administrative_area_level_1')
  end

  def city?
    types.include?('locality')
  end

  def latitude
    lonlat.lat if lonlat.present?
  end

  def longitude
    lonlat.lon if lonlat.present?
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

  def price_level(fetch_from_google: false)
    fetch_price_level if self[:price_level].nil? && fetch_from_google
    self[:price_level].present? && self[:price_level] >= 0 ? self[:price_level] : nil
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
      search = AttachedAsset.do_search(
        place: id, company_id: company_id, asset_type: 'photo', status: 'Active',
        sorting: :created_at, sorting_dir: :desc, per_page: 10)
      list_photos = search.results
    end
    list_photos.concat(spot.photos) if spot && list_photos.length < 10
    list_photos.slice(0, 10)
  end

  def location_ids
    @location_ids ||=
      if new_record?
        update_locations unless locations.any?
        locations.map(&:id)
      else
        locations.pluck('locations.id')
      end
  end

  def td_linx_match
    Place.td_linx_match(id, state_code)
  end

  # Merge the record with the given place
  def merge(place)
    fail 'Cannot merge a venue into a merged venued' unless merged_with_place_id.blank?
    fail 'Cannot merge place with itself' if id == place.id
    self.class.connection.transaction do
      Event.where(place_id: place.id).each do |event|
        event.update_attribute(:place_id, id) or fail('cannot update event')
      end

      Venue.where(place_id: place.id).each do |venue|
        real_venue = Venue.find_or_create_by(place_id: id, company_id: venue.company_id)
        # Update them one by one so the versions are generated
        venue.activities.each { |a| a.update_attribute(:activitable_id, real_venue.id) }
        venue.invites.update_all(venue_id: real_venue.id)
        venue.destroy
      end

      Placeable.where(place_id: place.id).update_all(place_id: id)

      place.td_linx_code ||= place.td_linx_code
      place.update_attribute(:merged_with_place_id, id)
    end
  end

  class << self
    def load_by_place_id(place_id, reference)
      Place.find_or_initialize_by(place_id: place_id) do |p|
        p.reference = reference
        p.send(:fetch_place_data)
      end
    end

    def political_division(place)
      return if place.nil?
      neighborhood = place.neighborhoods.first if place.neighborhoods.present?
      neighborhood ||= place.name if place.types.is_a?(Array) && place.types.include?('sublocality') && place.name != place.city
      [place.continent_name, place.country_name, place.state_name, place.city, neighborhood].compact if place.present?
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

    def state_name(country, state)
      return unless country && state
      Country.new(country).states[state.upcase]['name'] rescue nil
    end

    def combined_search(params)
      CombinedSearch.new(params).results
    end

    def latlon_for_city(name, state, country)
      points = Rails.cache.fetch("latlon_#{name.parameterize('_')}_#{state.parameterize('_')}_#{country.parameterize('_')}") do
        data = JSON.parse(open(URI.encode("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI::encode(name)}&components=country:#{URI::encode(country)}|administrative_area:#{URI::encode(state)}&sensor=false")).read)
        if data['results'].count > 0
          result = data['results'].detect { |r| r['geometry'].present? && r['geometry']['location'].present? }
          [result['geometry']['location']['lat'],  result['geometry']['location']['lng']] if result
        else
          nil
        end
      end
    end

    def google_client
      @client ||= GooglePlaces::Client.new(GOOGLE_API_KEY)
    end

    def find_place(binds)
      connection.select_value(
        sanitize_sql_array(['select find_place(:name, :street, :city, :state, :zipcode)', binds])
      ).try(:to_i)
    end

    def td_linx_match(id, state_code)
      connection.select_one(
        sanitize_sql_array(['select * from incremental_place_match(:id, :state)', id: id, state: state_code])
      )
    end
  end

  private

  def fetch_place_data
    return unless reference && !do_not_connect_to_api && spot
    self.name = spot.name
    self.lonlat = "POINT(#{spot.lng} #{spot.lat})"
    self.formatted_address = spot.formatted_address
    self.types = spot.types
    self.types ||= []

    parse_address_components spot.address_components

    return if types.include?('country')

    # Sometimes the API doesn't provide the state's long_name
    if country == 'US' && state =~ /^[A-Z]{1,2}$/
      self.state = load_country.states[administrative_level_1]['name'] rescue state if load_country
    end

    return if types.include?('administrative_area_level_1')

    find_city

    city.strip! unless city.nil?
    state.strip! unless state.nil?
    country.strip! unless country.nil?

    update_locations
    self
  end

  def parse_address_components(address_components)
    return unless address_components.present?
    # Parse the address components
    address_components.each do |component|
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
      elsif component['types'].include?('neighborhood')
        self.neighborhoods = [component['long_name']]
      end
    end
  end

  def find_city
    # Make sure the city returned by Google is the correct one
    validate_city_from_api

    sublocality = neighborhoods.join(' ') if neighborhoods.present?
    sublocality ||= route if self.types && self.types.include?('establishment')
    sublocality ||= zipcode if self.types && self.types.include?('establishment')

    # There are cases where the API doesn't give a city but a neighborhood (sublocality)
    return if city || self.types.include?('administrative_area_level_2') || sublocality.blank?

    spots = client.spots(latitude, longitude, keywords: sublocality)
    spots.each do |aspot|
      s = client.spot(aspot.reference)
      next unless s.address_components.present?
      city = s.address_components.find { |c| c['types'].include?('locality') }.try(:[], 'long_name')
      if city.present?
        self.city = city
        break
      end
    end

    # If still there is no city... :s then assign it's own name as the city
    # Example of places with this issue:
    # West Lake, TX: client.spot('CnRoAAAATClnCR7qKsJeD5nYegW8j9BLrDI2OsM-89wiA-NO-acvlYhSYXcef09z4Dns2p92zVfCCYJPET33QkrkzKeBt9y_fVOF-UfckvjwADE-rGsj4FIBJ4-s7O88LC0Y4yOz5e8vwYy5RjmMjx-dhG0IQxIQ3RfSNWKpoqim4qMLhdGhUhoUkH8hTzQ8E7Wgv6afi0RQmYzBP2Y')
    self.city ||= name if (%w(political natural_feature) & types).any?
  end

  def validate_city_from_api
    return unless city.present?
    results = client.spots(latitude, longitude, types: 'political', name: city, radius: 50_000)
    return if results.empty?

    results.each do |result|
      city_spot = client.spot(result.reference)
      if city_spot.city == city_spot.name || city_spot.name == city
        self.city = city_spot.city if city_spot.present? && city_spot.city.present?
        break
      end
    end
  end

  def spot
    @spot ||= client.spot(reference) if reference.present?
  rescue GooglePlaces::NotFoundError, GooglePlaces::OverQueryLimitError
    @spot = false
  end

  def client
    Place.google_client
  end

  def clear_cache
    Placeable.where(place_id: id).each(&:update_associated_resources)
  end

  def reindex_associated
    if merged_with_place_id.blank?
      Sunspot.index Venue.where(place_id: id)
    else
      Sunspot.remove Venue.where(place_id: id)
    end
    areas.each do |area|
      Area.update_common_denominators(area)
    end
  end

  def update_locations
    ary = Place.political_division(self)
    paths = ary.count.times.map { |i| ary.slice(0, i + 1).compact.join('/').downcase }.uniq
    self.locations = Location.load_by_paths(paths)
    self.location = locations.last
    self.is_location = (
      types.present? &&
      (((types & %w(
        sublocality political locality administrative_area_level_1 administrative_area_level_2
        administrative_area_level_3 country)).count > 0) ||
       (types.include?('natural_feature') && city.present?))
    )
    true
  end

  # Try to find the latitude and logitude based on a physicical address and returns
  # true if found or false if not
  def set_lat_lng
    return if do_not_connect_to_api
    return if latitude.present? && longitude.present?
    address_txt = URI.encode([street_number, route, city,
                              state.to_s + ' ' + zipcode.to_s, country].compact.join(', '))

    data = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?address=#{address_txt}&sensor=true").read)
    return unless data['results'].count > 0
    result = data['results'].find { |r| r['geometry'].present? && r['geometry']['location'].present? }
    return unless result
    self.lonlat = "POINT(#{result['geometry']['location']['lng']} #{result['geometry']['location']['lat']})"
  end

  def fetch_price_level
    self[:price_level] =
      if spot.present? && spot.price_level.present?
        spot.price_level.to_i
      else
        -1
      end
    save
  end

  def valid_types?
    if types.nil? || types.empty?
      errors.add :types, :blank
    elsif (types - VALID_GOOGLE_TYPES - ADDITIONAL_GOOGLE_TYPES).any?
      errors.add :types, :invalid
    end
  end
end
