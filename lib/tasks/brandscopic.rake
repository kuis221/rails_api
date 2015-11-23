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
    require 'thwait'
    origin_bucket = ENV['ORIGIN'] || 'brandscopic-prod'
    fail 'Cannot copy to the same bucket' if ENV['S3_BUCKET_NAME'] == origin_bucket
    first_id = ENV.key?('START') ? ENV['START'].to_i : 0
    last_id = ENV.key?('END') ? ENV['END'].to_i : AttachedAsset.last.id
    number_threads = ENV.key?('THREADS') ? ENV['THREADS'].to_i : 5
    s3 = AWS::S3.new

    # Start the threads
    threads = []
    (first_id..last_id).to_a.in_groups_of(((last_id - first_id) / (number_threads - 1)).to_i, false) do |group|
      threads << Thread.new do
        p "Starting thread to process assets from #{group.first} to #{group.last}"
        AttachedAsset.where(attachable_type: 'EventExpense').where(id: group.first.to_i..group.last.to_i).find_each do |at|
          (at.file.styles.keys + [:original]).each do |style_name|
            key = at.file.path(style_name).gsub(/^\//, '')
            begin
              s3.buckets[origin_bucket].objects[key].copy_to(
                key, bucket_name: ENV['S3_BUCKET_NAME'], acl: :public_read)
            rescue
            end
          end
        end
      end
    end

    # Wait for the threads to complete
    ThreadsWait.all_waits(*threads)
  end

  desc 'Merge venues from a CSV file sent through the STDIN'
  task merge_venues: :environment do
    merger = Brandscopic::Utils::VenueMerger.new($stdin)
    if merger.validate
      merger.run!
    else
      puts merger.errors.map { |e| "[Line ##{e[:line]}] #{e[:error]}" }.join("\n")
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
