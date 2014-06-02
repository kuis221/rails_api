class Analysis::TrendsReportController < FilteredController
  before_filter :authorize_actions

  defaults resource_class: TrendObject

  helper Analysis::TrendsReport

  skip_load_and_authorize_resource

  def index
  end

  def items
    render json: trend_words
  end

  def show
    @term = params[:term]
    @search_params = search_params.reject{|k, v| k == 'term' }.merge(words: [@term])
    @info = trend_words.first
    raise ActiveRecord::RecordNotFound if @info.nil? || @info[:name] != @term
  end

  def over_time
    render json: word_trending_over_time_data
  end

  def across_locations
    render json: word_trending_across_locations
  end

  def search
    @search_params = search_params.reject{|k, v| k == 'term' }.merge(prefix: params[:term], limit: 10)
    render json: trend_words
  end

  def mentions
    @term = params[:term]
    render layout: false
  end

  private

    def authorize_actions
      authorize! :access, :trends_report
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        if bucket = build_source_bucket
          f.push bucket
        end
        f.push build_campaign_bucket
        f.push build_brands_bucket
        f.push build_areas_bucket
      end
    end

    def build_source_bucket
      activity_types = current_company.activity_types.active.with_trending_fields
      if activity_types.any?
        items =  [{label: 'Comments', id: "Comment", name: :source, count: 1}]
        items += activity_types.map{|at| build_facet_item({label: at.name, id: "ActivityType:#{at.id}", name: :source, count: 1}) }
        {label: 'Source', items: items}
      else
        nil
      end
    end

    def trend_words
      search = resource_class.do_search(search_params)
      words = search.facet(:description).rows.map{|r| { name: r.value, count: r.count, current: 0, previous: 0, trending: :stable } }
      add_trending_values words  # Updates the values for current, previous and trending
      words
    end

    def word_trending_over_time_data
      # Search for the # occurrences of the work on each day
      search = resource_class.do_search(company_id: current_company.id, term: params[:term])
      data = Hash[search.facet(:start_at).rows.map do |r|
        [r.value.first.to_s(:numeric).to_i, [r.value.first.to_datetime.strftime('%Q').to_i, r.count]]
      end]

      # fill in each missing day between the first and last days with zeros
      if data.count > 1
        (Date.strptime(data[data.keys.first][0].to_s,'%Q').to_date..Date.strptime(data[data.keys.last][0].to_s,'%Q').to_date).each do |day|
          data[day.to_s(:numeric).to_i] ||= [day.strftime('%Q').to_i, 0]
        end
      end

      # Sort by keys (days) and return the values
      data.sort.to_h.values
    end

    def word_trending_across_locations
      search = TrendObject.solr_search do
        with :company_id, current_company.id
        with :description, params[:term]
        if params[:country].present? && params[:country] && params[:state].present? && params[:state]
          with :state, params[:state]
          with :country, params[:country]
          facet :city
        elsif params[:country].present? && params[:country]
          with :country, params[:country]
          facet :state
        else
          facet :country
        end
      end

      rows = []
      search.facets.first.tap do |f|
        rows = search.facet(f.name).rows.map{|fr| [fr.value, fr.count] }
      end
      if params[:state] && params[:country]
        rows = [['Latitude', 'longitude', 'City', 'Mentions']] +
               add_latlon_cities(params[:country], params[:state], rows) if params[:state] && params[:country]
      elsif params[:country]
        country = Country.new(params[:country])
        rows.each{|state| state[0] = country.states[state[0]]['name'] if country.states[state[0]].present? } if country.present?
        rows = [['State', 'Mentions']] + rows
      else
        rows.each{|row| row[1], row[2] = [country.name, row[1]] if country = Country.new(row[0])}
        rows = [['Country Code', 'Country', 'Mentions']] + rows
      end
      rows
    end

    def add_trending_values(words)
      # Determine how each work have been trending...
      if words.any?
        workds_hash = Hash[words.map{|w| [w[:name], w] }]
        time_period = 2.weeks
        ratio = 10.0/100.0  # The differecen between periods should lower/greater than 10%  to be considered
                        # and trending down/up
        facet_params = search_params.dup
        facet_params[:words] = workds_hash.keys

        facet_params[:start_date] = time_period.ago.to_s(:slashes)
        facet_params[:end_date] = Date.today.to_s(:slashes)
        rows = resource_class.do_search(facet_params).facet(:description).rows
        rows.each do |r|
          if workds_hash.has_key?(r.value)
            workds_hash[r.value][:current] = r.count
            workds_hash[r.value][:trending] = :up
          end
        end

        facet_params[:start_date] = ((time_period*2).ago-1.day).to_s(:slashes)
        facet_params[:end_date] = (time_period.ago-1.day).to_s(:slashes)
        resource_class.do_search(facet_params).facet(:description).rows.each do|r|
          if workds_hash.has_key?(r.value)
            workds_hash[r.value][:previous] = r.count
            workds_hash[r.value][:trending] =  :down if r.count > workds_hash[r.value][:current]
            margin = workds_hash[r.value][:current] * ratio
            range = (workds_hash[r.value][:current]-margin)..(workds_hash[r.value][:current]+margin)
            workds_hash[r.value][:trending] = :stable if range.include? r.count
          end
        end
      end
    end

    # Returns a new array of cities with the first two columns containing the latitude and longitude,
    # the third one with the city name and the last one the count
    def add_latlon_cities(country_name, state_code, cities)
      country = Country.new(country_name)
      unless country.nil?
        state_name = country.states[state_code]['name'] unless country.nil?
        city_names = cities.map{|r| r[0] }
        locations = Hash[Place.where('types like \'%political%\'').
          where(state: state_name, country: country_name, name: city_names).map do |place|
           [place.name, [place.latitude, place.longitude, place.name]]
        end]

        cities.map do |city|
          if locations.has_key?(city[0]) # If the city was found on the database
            locations[city[0]] + [city[1]]
          elsif points = Place.latlon_for_city(city[0], state_code, country_name)
            points + [city[0], city[1]]
          end
        end.compact
      else
        cities
      end
    end
end