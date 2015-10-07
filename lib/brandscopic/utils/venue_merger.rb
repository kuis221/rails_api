module Brandscopic
  module Utils
    class VenueMerger
      attr_accessor :errors, :column_index, :options
      # Receives a file hanlder. This allows to send the $stdin from the
      # rake file. The file loaded in an array to allow go through
      # it more than once
      def initialize(file, options = {})
        @rows = []
        opts = { row_sep: "\n", col_sep: ',', skip_blanks: true }.merge(options)
        CSV(file, opts) do |csv|
          csv.each do |r|
            @rows.push(r)
          end
        end
        @column_index = {
          name: 3, route: 4, city: 5, state: 6, zip: 7, td_linx_code: 8
        }
      end

      def run!
        @rows.each do |row|
          ids = venue_ids(row)
          next if ids.empty?
          venues = Venue.where(id: ids)
          name, route, city, state, zip, td_linx_code = split_row(row)

          place = venues.find { |v| v.place.merged_with_place_id.nil? }.place
          places_to_merge = venues.map(&:place) - [place]
          logger.info "Merging #{place.name} with #{places_to_merge.map(&:name).to_sentence} keeping the name: #{name}"
          place.name = name.strip
          place.route = route.gsub(/^[0-9]+\w/, '').strip
          place.street_number = route.gsub(/^([0-9]+).*$/, '\1').strip
          place.zipcode = zip.strip
          place.city = city.strip
          place.state = state.strip
          place.state = Country.new(place.country).states[state.upcase.strip]['name']  if state.strip =~ /^[A-Z]{2}$/i
          place.td_linx_code = td_linx_code.strip unless td_linx_code.blank?
          place.save
          places_to_merge.each do |merged_place|
            place.merge(merged_place)
          end
        end
      end

      def validate
        @errors = []
        @rows.each_with_index do |row, i|
          ids = venue_ids(row)
          venues = Venue.where(id: ids).to_a
          if ids.compact.count > venues.count
            @errors.push(line: i + 1, error: "The following venues were not found: #{(ids - venues.map(&:id))} -> #{venues.map(&:id)}")
            next
          end

          if ids.count <= 1
            @errors.push(line: i + 1, error: 'Must provide more than one venue ID')
            next
          end

          if venues.all? { |v| v.place.merged_with_place_id }
            @errors.push(line: i + 1, error: 'All the given venues have already been merged')
            next
          end

          if venues.map(&:place_id).uniq.count < venues.count
            @errors.push(line: i + 1, error: 'Two or more venues are sharing the same place id #{[venue1, venue2, venue3]}')
            next
          end

          if venues.map(&:company_id).uniq.count > 1
            @errors.push(line: i + 1, error: 'All venues must be in the same company to merge them')
            next
          end
        end
        @errors.empty?
      end

      def col(row, name)
        row[column_index[name]]
      end

      def venue_ids(row)
        [row[0], row[1], row[2]].reject(&:blank?).map(&:to_i).uniq
      end

      def split_row(row)
        @column_index.map { |_k, i| row[i]  }
      end

      def logger
        Rails.logger
      end
    end
  end
end
