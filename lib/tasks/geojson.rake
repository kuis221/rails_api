require 'open-uri'

namespace :geojson do
  desc 'Parse and load the neighborhoods from the geojson files into the database'
  task load_neighborhoods: :environment do
    ActiveRecord::Base.connection.execute(IO.read('db/neighborhoods.sql'))
  end

  desc 'Parse and load the neighborhoods from the geojson files into the database'
  task :load_file, [:file, :state, :city] => [:environment] do |_t, args|
    scope = Neighborhood.where(city: args[:city], state: args[:state])
    zipcodes = scope.joins('INNER JOIN zipcode_locations z ON neighborhoods.gid=z.neighborhood_id').pluck('zipcode')
    scope.delete_all
    p 'Downloading and parsing Geojson file'
    JSON.parse(open(args[:file]).read)['features'].each do |neighborhood|
      p "  Creating #{neighborhood['properties']['label']}"
      n = Neighborhood.create(
        name: neighborhood['properties']['label'],
        city: args[:city],
        state: args[:state],
        geog: RGeo::GeoJSON.decode(force_multipolygon(neighborhood['geometry']).to_json, json_parser: :json)
      )
    end
    p 'Updating zipcode mappings'
    zipcodes.each { |zipcode| InviteRsvp.update_zip_code_location(zipcode) }
  end

  def force_multipolygon(geometry)
    if geometry['type'] == 'Polygon'
      { 'type' => 'MultiPolygon', 'coordinates' => [geometry['coordinates']] }
    else
      geometry
    end
  end
end
