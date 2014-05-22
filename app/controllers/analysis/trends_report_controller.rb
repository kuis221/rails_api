class Analysis::TrendsReportController < FilteredController
  before_filter :authorize_actions

  defaults resource_class: TrendObject

  skip_load_and_authorize_resource

  def index
  end

  def items
    render json: trend_words
  end

  def show
    @term = params[:term]
  end

  def over_time
    render json: word_trending_over_time_data
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
      words = Hash[search.facet(:description).rows.map{|r| [r.value, { name: r.value, count: r.count, current: 0, previous: 0, trending: :stable }] }]
      facet_params = search_params.dup
      facet_params[:start_date] = 2.weeks.ago.to_s(:slashes)
      facet_params[:end_date] = Date.today.to_s(:slashes)
      if words.any?
        facet_params[:words] = words.keys
        rows = resource_class.do_search(facet_params).facet(:description).rows
        rows.each do |r|
          if words.has_key?(r.value)
            words[r.value][:current] = r.count
            words[r.value][:trending] = :up
          end
        end

        facet_params[:start_date] = (4.weeks.ago-1.day).to_s(:slashes)
        facet_params[:end_date] = (2.weeks.ago-1.day).to_s(:slashes)
        resource_class.do_search(facet_params).facet(:description).rows.each do|r|
          if words.has_key?(r.value)
            words[r.value][:previous] = r.count
            words[r.value][:trending] =  :down if r.count > words[r.value][:current]
            words[r.value][:trending] =  :stable if r.count == words[r.value][:current]
          end
        end
      end

      words.values
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
end