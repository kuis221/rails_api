# == Schema Information
#
# Table name: accounts
#
#  id           :integer          not null, primary key
#  name         :string(255)
#  td_linx_code :string(255)
#  url          :string(255)
#  description  :text
#  active       :boolean          default(TRUE)
#  creator_id   :integer
#  updater_id   :integer
#  created_at   :datetime
#  updated_at   :datetime
#  neighborhood :string(255)
#

require 'open-uri'
require 'json'

class Legacy::Account < Legacy::Record
  self.table_name = "legacy_accounts"
  has_many      :events

  has_many :data_migrations, as: :remote


  def synchronize(company, attributes={})
    migration = data_migrations.find_or_initialize_by_company_id(company.id)
    unless migration.local.present?
      migration.local = find_place_on_api
      unless migration.local.present?
        p "Place not found [#{name}]: #{address.to_json}"
      end
      migration.local ||= ::Place.new(migration_attributes.merge(attributes), without_protection: true)
      migration.local.is_custom_place = true
    end
    migration.local.td_linx_code = td_linx_code
    migration.save
    migration
  end

  def find_place_on_api
    place = find_options_in_api(1).first
  end

  def find_options_in_api(max=5)
    options = []
    if address.present?
      address_txt = URI::encode("#{address.street_address}, #{address.city}, #{address.state} #{address.postal_code}").strip
      result = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?address=#{address_txt}&sensor=true").read)
      if result['results'].count > 0
        location = result['results'].first['geometry']['location']
        spots = Legacy::Migration.api_client.spots(location['lat'], location['lng'], name: name, :radius => 3000)
        spots += Legacy::Migration.api_client.spots(location['lat'], location['lng'], keyword: name, :radius => 1000) if spots.empty?

        if spots.any?
          options = spots.first(max).map { |spot| ::Place.load_by_place_id(spot.id, spot.reference) }
        end
      end
    end
    options
  end

  def state_name
    Country.new('US').states[address.state]['name'] rescue address.state
  end

  def migration_attributes(attributes={})
    location = {'lat' => nil, "lng" => nil}
    address_txt = "#{address.city}, #{address.state}"
    address_txt = "#{address_txt}, #{address.postal_code}" if address.postal_code.present?
    result = JSON.parse(open("http://maps.googleapis.com/maps/api/geocode/json?address=#{URI::encode(address_txt)}&sensor=true").read)
    location = result['results'].first['geometry']['location'] if result['results'].count > 0
    {
      name: name,
      formatted_address: "#{address.street_address}, #{address.city}, #{address.state} #{address.postal_code}",
      latitude: location['lat'].to_s,
      longitude: location['lng'].to_s,
      route:  address.street_address,
      zipcode:  address.postal_code,
      city:  address.city,
      state:  state_name,
      is_custom_place: true,
      country: 'US'
    }
  end

  def address
    @address ||= Legacy::Address.find_by_addressable_type_and_addressable_id('Account', self.id)
  end
end
