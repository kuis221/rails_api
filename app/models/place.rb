# == Schema Information
#
# Table name: places
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  reference         :string(400)
#  place_id          :string(100)
#  types             :string(255)
#  formatted_address :string(255)
#  latitude          :float
#  longitude         :float
#  street_number     :string(255)
#  route             :string(255)
#  zipcode           :string(255)
#  city              :string(255)
#  state             :string(255)
#  country           :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Place < ActiveRecord::Base
  track_who_does_it

  attr_accessible :reference, :place_id

  validates :place_id, presence: true, uniqueness: true
  validates :reference, presence: true, uniqueness: true

  # Areas-Places relationship
  has_many :areas_places
  has_many :areas, through: :areas_places

  before_create :fetch_place_data

  serialize :types

  def street
    "#{street_number} #{route}".strip
  end

  def country_name
    load_country.name rescue nil unless load_country.nil?
  end

  def state_name
    load_country.states[state]['name'] rescue nil if load_country and state
  end

  def continent_name
    load_country.continent if load_country
  end

  def load_country
    @the_country ||= Country.new(country) if country
  end

  class << self
    def load_organized
      places = find(:all).map {|p| {label: p.name, id: p.id, parents: [p.continent_name, p.country_name, p.state_name, p.city].compact, count: 1} }
      list = {label: :root, items: [], id: nil}
      places.each do |p|
        add_place_into_parent(p, p[:parents], list)
      end
      simplify_list(list)[:items]
    end

    private
      def add_place_into_parent(p, parents, list)
        unless parent = list[:items].select{|p| p[:label] == parents[0]}.shift
          parent = {label: parents[0], items: [], name: 'place', id: [list[:id], parents[0]].compact.join('/').downcase}
          list[:items].push parent
        end
        if parents.size == 1
          parent[:items].push p
        else
          add_place_into_parent(p, parents.slice(1..-1), parent)
        end
      end

      def simplify_list(parent)
        if parent.has_key?(:items) and parent[:items]
          parent[:items].each_with_index do |item, i|
            parent[:items][i] = simplify_list(item)
          end
        end

        if parent.has_key?(:items) and parent[:items].size == 1
          simplify_list(parent[:items][0])
        else
          parent
        end
      end
  end

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

  private

    def fetch_place_data
      if reference
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
            self.state = component['short_name']
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
      end
    end

    def client
      @client ||= GooglePlaces::Client.new(GOOGLE_API_KEY)
    end
end
