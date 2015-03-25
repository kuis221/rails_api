namespace :brandscopic do
  desc 'Find and Merge duplicated venues'
  task find_and_merge_duplicated_venues: :environment do
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

  desc 'Merge venues '
  task merge_venues: :environment do
    Place.connection.transaction do
      CSV($stdin, row_sep: "\n", col_sep: ',') do |csv|
        csv.each do |venue1, venue2, venue3, name, route, city, state, zip, td_linx_code|
          next if venue1.blank?
          venues = Venue.find([venue1, venue2, venue3])
          raise "NOT ALL VENUES WHERE FOUND #{[venue1, venue2, venue3].compact}" if [venue1, venue2, venue3].compact.count > venues.count
          raise "TWO OR MORE VENUES ARE SHARING THE SAME PLACE ID #{[venue1, venue2, venue3]}" if venues.map(&:place_id).uniq.count < venues.count
          if venues.count > 1
            puts "Merging #{venues.first.name} with #{venues[1, 2].map(&:name).join(' and ')} keeping the name: #{name}"
            place = venues.first.place
            place.name = name.strip
            place.route = route.gsub(/^[0-9]+\w/, '').strip
            place.street_number = route.gsub(/^([0-9]+)\w.*$/, '$1').strip
            place.zipcode = zip.strip
            place.city = zip.strip
            place.state = state.strip
            place.td_linx_code = td_linx_code.strip unless td_linx_code.blank?
            place.save
            place.merge(venues[1].place)
            place.merge(venues[2].place) if venues.count > 2
          else
            p "Only one venue was found for for #{[venue1, venue2, venue3]}"
          end
        end
      end
    end
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
