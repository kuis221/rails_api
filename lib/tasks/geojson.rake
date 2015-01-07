namespace :geojson do
  desc 'Parse and load the neighborhoods from the geojson files into the database'
  task load_neighborhoods: :environment do
    Dir["#{Rails.root}/db/neighborhoods/*.geojson"].each do |f|
      JSON.parse(File.read(f))['features'].each do |neighborhood|
        Neighborhood.create(
          name: neighborhood['properties']['NAME'],
          city: neighborhood['properties']['CITY'],
          state: Place.state_name('US', neighborhood['properties']['STATE']),
          county: neighborhood['properties']['COUNTY'],
          country: 'US',
          geometry: JSON.generate(neighborhood['geometry'])
        )
      end
    end
  end

  task :load_zetashape_city, [:file, :country, :state] => [:environment] do |t, args|
    JSON.parse(File.read(args[:file]))['features'].each do |neighborhood|
      city = nil
      latlng = neighborhood['geometry']['coordinates'].first.first
      latlng = latlng.first if latlng.count > 2
      p "#{neighborhood['properties']['label']} ==> #{latlng.inspect}"
      spot = Place.google_client.spots(latlng[1], latlng[0], types: ['neighborhood'], keyword: neighborhood['properties']['label']).first
      spot = Place.google_client.spot(spot.reference) if spot
      if spot && spot.address_components.present?
        p "  Found neighborhood #{spot.name}"
        city = spot.address_components.find { |c| c['types'].include?('locality') }.try(:[], 'long_name')
        p "     City: #{city}"
      end
      unless city
        spot = Place.google_client.spots(latlng[1], latlng[0], types: ['city']).first
        city = spot.name if spot
        p "     City: #{city}"
      end
    end
  end
end
