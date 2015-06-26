class Api::V1::FilteredController < Api::V1::ApiController
  inherit_resources

  helper_method :facets, :collection_count, :total_pages

  def collection
    @collection_count = solr_search.total
    @total_pages = solr_search.results.total_pages
    set_collection_ivar(solr_search.results)
  end

  def solr_search
    @solr_search ||= resource_class.do_search(search_params)
  end

  attr_reader :collection_count

  attr_reader :total_pages

  protected

  def paginated_result
    results = collection
    PaginatedResult.new(
      page: params[:page] || 1,
      total: collection_count,
      results: results)
  end

  def search_params
    @search_params ||= permitted_search_params.tap do |p|  # Duplicate the params array to make some modifications
      p[:company_id] = current_company.id
      p[:current_company_user] = current_company_user
    end
  end

  def build_resource_params
    [permitted_params || {}]
  end
end
