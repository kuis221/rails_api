class Analysis::TrendsReportController < FilteredController
  before_filter :authorize_actions

  defaults resource_class: TrendObject

  skip_load_and_authorize_resource

  def index
  end

  def items
    search = resource_class.do_search(search_params)
    @trend_words = search.facet(:description).rows.map{|r| { name: r.value, count: r.count } }
    render json: @trend_words
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
end