class DateRangesController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  authorize_resource

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  protected
    def collection_to_json
      collection.map{|range| {
        :id => range.id,
        :name => range.name,
        :description => range.description,
        :status => range.active? ? 'Active' : 'Inactive',
        :active => range.active?,
        :links => {
            edit: edit_date_range_path(range),
            show: date_range_path(range),
            activate: activate_date_range_path(range),
            deactivate: deactivate_date_range_path(range),
            delete: date_range_path(range),
        }
      }}
    end

    def collection
      @date_ranges ||= begin
        # Search date ranges
        search = Sunspot.search(DateRange) do
          with(:company_id, current_company.id)

          order_by(params[:sorting] || :name , params[:sorting_dir] || :desc)
          paginate :page => (params[:page] || 1)
        end
        @date_ranges = search.results
        @collection_count = search.total


        # Get the facets without all the filters
        if params[:facets] == 'true'
          search = Sunspot.search(DateRange) do
            with(:company_id, current_company.id)
            facet :status
          end
          @facets = []
          @facets.push(label: "Status", items: search.facet(:status).rows.map{|x| {label: x.value, id: x.value, name: :status, selected: (x.value =='Active'), count: x.count} })
        end
        @date_ranges
      end
    end
end
