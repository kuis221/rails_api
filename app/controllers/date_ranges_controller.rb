class DateRangesController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  authorize_resource

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper


  def autocomplete
    buckets = []

    # Search compaigns
    search = Sunspot.search(DateRange) do
      keywords(params[:q]) do
        fields(:name)
      end
      with(:company_id, current_company.id)
    end
    buckets.push(label: "Date Ranges", value: search.results.first(5).map{|x| {label: x.name, value: x.id, type: x.class.name.downcase} })

    render :json => buckets.flatten
  end


  protected

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we used for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)
        f.push(label: "Status", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
      end
    end

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
end
