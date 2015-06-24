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
        count += 1
      end
    end

    puts "Found #{count} duplicates\n"
  end

  desc 'Copy all assets production to this environment\'s bucket'
  task synch_assets: :environment do
    origin_bucket = ENV['ORIGIN'] || 'brandscopic-prod'
    fail 'Cannot copy to the same bucket' if ENV['S3_BUCKET_NAME'] == origin_bucket
    first_id = ENV['START'] || 0
    last_id = ENV['END'] || AttachedAsset.last.id
    s3 = AWS::S3.new
    AttachedAsset.photos.where(id: first_id..last_id).where(attachable_type: 'Event')
      .joins('INNER JOIN events ON events.id=attachable_id').find_each do |at|
      if at.file.exists?
        Rails.logger.info "Skpping asset #{at.id} because it exists in the bucket #{ENV['S3_BUCKET_NAME']}"
        next
      end
      (at.file.styles.keys + [:original]).each do |style_name|
        key = at.file.path(style_name).gsub(/^\//,'')
        begin
          if s3.buckets[origin_bucket].objects[key].exists?
            s3.buckets[origin_bucket].objects[key].copy_to(
              key, :bucket_name => ENV['S3_BUCKET_NAME'], acl: :public_read)
          end
        rescue
        end
      end
    end
  end

  desc 'Merge venues from a CSV file sent through the STDIN'
  task merge_venues: :environment do
    CSV($stdin, row_sep: "\n", col_sep: ',') do |csv|
      csv.each do |venue1, venue2, venue3, name, route, city, state, zip, td_linx_code|
        next if venue1.blank?
        venues = Venue.where(id: [venue1, venue2, venue3]).where(merged_with_place_id: nil)
        if [venue1, venue2, venue3].compact.count > venues.count
          puts "NOT ALL VENUES WHERE FOUND #{[venue1, venue2, venue3].compact}"
          next
        end
        raise "TWO OR MORE VENUES ARE SHARING THE SAME PLACE ID #{[venue1, venue2, venue3]}" if venues.map(&:place_id).uniq.count < venues.count
        if venues.count > 1
          puts "Merging #{venues.first.name} with #{venues[1, 2].map(&:name).join(' and ')} keeping the name: #{name}"
          place = venues.first.place
          place.name = name.strip
          place.route = route.gsub(/^[0-9]+\w/, '').strip
          place.street_number = route.gsub(/^([0-9]+).*$/, '\1').strip
          place.zipcode = zip.strip
          place.city = city.strip
          place.state = state.strip
          place.state = Country.new(place.country).states[state.upcase.strip]['name']  if state.strip =~ /^[A-Z]{2}$/i
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

  desc 'Fix places place_id'
  task fix_place_id: :environment do
    Place.where('char_length(place_id) > 39').where.not(reference: nil).find_each do |place|
      begin
        sleep Random.rand(2)
        spot = place.send(:spot)
        next unless spot.present?
        place.update_column(:place_id, spot.place_id) unless place.place_id == spot.place_id
      rescue e
        puts "Failed updating place ##{place.id}: #{e.inspect}"
      end
    end
  end
end
