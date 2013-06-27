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
#
require "base64"

class Place < ActiveRecord::Base

  attr_accessible :reference, :place_id

  validates :place_id, presence: true, uniqueness: true
  validates :reference, presence: true, uniqueness: true

  # Areas-Places relationship
  has_many :areas_places
  has_many :areas, through: :areas_places

  attr_accessor :do_not_connect_to_api
  before_create :fetch_place_data

  serialize :types

  searchable do
    text :name

    text :formatted_address

    latlon(:location) { Sunspot::Util::Coordinates.new(latitude, latitude) }

    string :name
    string :country
    string :state
    string :city
    string :types, multiple: true
  end

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

  class << self
    def load_organized(company_id)
      places = find(:all)
      list = {label: :root, items: [], id: nil, path: nil}

      Area.joins(:places).where(places: {id: places.map(&:id)}, company_id: company_id).each do |area|
        p  = create_structure(list, area.common_denominators)
        p[:items] ||= []
        p[:items].push({label: area.name, id: area.id, count: 1, name: :area, group: 'Areas'})
      end

      places.each do |p|
        parents = [p.continent_name, p.country_name, p.state_name, p.city].compact
        create_structure(list, parents)
      end

      list[:items]
      simplify_list list[:items]
    end

    def encode_location(path)
      path = path.compact.join('/') if path.is_a?(Array)
      Digest::MD5.hexdigest(path.downcase)
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

  private

    def fetch_place_data
      if reference && !do_not_connect_to_api
        spot = client.spot(reference)
        self.name = spot.name
        self.latitude = spot.lat
        self.longitude = spot.lng
        self.formatted_address = spot.formatted_address
        self.types = spot.types

        # Parse the address components
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
          end
        end

        # Sometimes the API doesn't provide the state's long_name
        if self.country == 'US' && self.state =~ /^[A-Z]{1,2}$/
          self.state = load_country.states[administrative_level_1]['name'] rescue self.state if load_country
        end
      end
    end

    def client
      @client ||= GooglePlaces::Client.new(GOOGLE_API_KEY)
    end
end
