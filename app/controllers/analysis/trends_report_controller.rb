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
end