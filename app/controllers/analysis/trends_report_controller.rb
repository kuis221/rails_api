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
    @term = params[:term]
    start = 100.days.ago
    render json: 100.times.map{|i| [(start+i.days).to_datetime.strftime('%Q').to_i, rand(20)] }
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
end