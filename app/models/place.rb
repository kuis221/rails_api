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

  attr_accessible :reference, :place_id, :name, :types, :street_number, :route, :city, :state, :zipcode, :country

  validates :place_id, presence: true, uniqueness: true, unless: :is_custom_place, on: :create
  validates :reference, presence: true, uniqueness: true, unless: :is_custom_place, on: :create

  # Areas-Places relationship
  has_many :events
  has_many :placeables

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
      Place.find_or_initialize_by_place_id(place_id: place_id, reference: reference) do |p|
        p.send(:fetch_place_data)
      end
    end

    def locations_for_index(place)
      locations = []
      unless place.nil?
        locations.push encode_location(place.continent_name) if place.continent_name
        locations.push encode_location([place.continent_name, place.country_name]) if place.country_name
        locations.push encode_location([place.continent_name, place.country_name, place.state_name]) if place.state_name
        locations.push encode_location([place.continent_name, place.country_name, place.state_name, place.city]) if  place.state_name && place.city
        locations.push encode_location([place.continent_name, place.country_name, place.state_name, place.city.gsub('Saint','St')]) if  place.state_name && place.city && place.city =~ /^Saint.*/
      end
      locations
    end

    def location_for_index(place)
      unless place.nil?
        return encode_location([place.continent_name, place.country_name, place.state_name, place.city])+'||'+place.city if place.state_name && place.city
        return encode_location([place.continent_name, place.country_name, place.state_name])+'||'+place.state_name if place.state_name
        return encode_location([place.continent_name, place.country_name])+'||'+place.country_name if place.country_name
        return encode_location(place.continent_name)+'||'+place.continent_name if place.continent_name
      end
    end

    def location_for_search(place)
      unless place.nil?
        return nil if place.types.present? && place.types.include?('establishment')
        return encode_location([place.continent_name, place.country_name, place.state_name, place.city]) if place.state_name && place.city
        return encode_location([place.continent_name, place.country_name, place.state_name]) if place.state_name
        return encode_location([place.continent_name, place.country_name]) if place.country_name
        return encode_location(place.continent_name) if place.continent_name
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
      local_results = Venue.do_search(params.merge(per_page: 5)).results
      results = local_results.map do |p|
        address = (p.formatted_address || [p.city, (p.country == 'US' ? p.state : p.state_name), p.country].compact.join(', '))
        {value: p.name + ', ' + address, label: p.name + ', ' + address, id: p.place_id}
      end
      local_references = local_results.map{|p| p.reference}.compact

      google_results = JSON.parse(open("https://maps.googleapis.com/maps/api/place/textsearch/json?key=#{GOOGLE_API_KEY}&sensor=false&query=#{URI::encode(params[:q])}").read)
      if google_results && google_results['results'].present?
        results += google_results['results'].reject{|p| local_references.include?(p['reference']) }.map{|p| {value: p['name'] + ', ' + p['formatted_address'].to_s, label: p['name'] + ', ' + p['formatted_address'].to_s, id: "#{p['reference']}||#{p['id']}"} }
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
              sublocality = component['long_name']
            end
          end
        end

        # Sometimes the API doesn't provide the state's long_name
        if self.country == 'US' && self.state =~ /^[A-Z]{1,2}$/
          self.state = load_country.states[administrative_level_1]['name'] rescue self.state if load_country
        end

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
        end
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
