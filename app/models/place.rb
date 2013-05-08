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
#  zipcode           :string(255)
#  city              :string(255)
#  state             :string(255)
#  country           :string(255)
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Place < ActiveRecord::Base
  attr_accessible :reference, :place_id

  validates :place_id, presence: true, uniqueness: true
  validates :reference, presence: true, uniqueness: true

  before_create :fetch_place_data

  serialize :types

  def street
    "#{street_number} #{route}"
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
