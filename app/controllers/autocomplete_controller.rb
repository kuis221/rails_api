class AutocompleteController < ApplicationController
  def show
    render json: { filters: collection_filters.filters }
  end

  def collection_filters
    @collection_filters ||= CollectionFilter.new(params[:id], current_company_user, params)
  end
end