namespace :brandscopic do
  desc 'Merge duplicated venues'
  task merge_duplicated_venues: :environment do
    count = 0
    processed_ids = []
    Place.find_each do |place|
      next if processed_ids.include?(place.id)
      Place.where.not(id: place.id).where(name: place.name, city: place.city, state: place.state, route: place.route).each do |copy|
        puts "Copy found:\n"
        puts "   ORIGINAL: #{place.inspect}\n"
        puts "   COPY:     #{copy.inspect}\n"
        processed_ids.concat [place.id, copy.id]
        place.merge(copy)
        count += 1;
      end
    end

    puts "Found #{count} duplicates\n"
  end

  desc 'Fix places place_id'
  task fix_place_id: :environment do
    Place.where.not(place_id: nil).where.not(place_id: '').find_each do |place|
      spot = place.send(:spot)
      next unless spot.present?
      place.place_id = spot.place_id
      sleep Random.rand(3)
    end
  end
end