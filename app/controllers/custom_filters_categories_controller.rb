# Custom Filters Categories Controller class
#
# This class handle the requests for managing the Custom Filters Categories
#
class CustomFiltersCategoriesController < InheritedResources::Base
  respond_to :js, only: [:index, :new, :create]
  respond_to :json, only: [:list_filters]
  actions :index, :new, :create

  def create
    create! do |success|
      success.json { render json: { result: 'OK' } }
    end
  end

  def list_filters
    groups = {}
    CustomFiltersCategory.for_company_user(current_company_user)
      .order('custom_filters_categories.name').each do |category|
        groups[category.name.upcase] ||= []
        category.customFilters.where(apply_to: "events").each do |filter|
          groups[category.name.upcase].push filter
        end
      end
    list = groups.map do |group, filters|
      { label: group,
         items: filters.map do |cf|
          {
            id: cf.id,
            filters: cf.filters,
            name: cf.name
          }
        end }
    end
    render json: list
  end

  private

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    params.permit(custom_filters_category: [
      :id, :name])[:custom_filters_category]
  end
end