class FiltersController < ApplicationController
  def show
    render json: { filters: collection_filters.filters }
  end

  def expand
    render json: collection_filters.expand(params[:filter_type], params[:filter_id])
  end

  def collection_filters
    @collection_filters ||= CollectionFilter.new(params[:id], current_company_user, params)
  end
end
