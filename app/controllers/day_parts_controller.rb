class DayPartsController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  authorize_resource

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def autocomplete
    buckets = autocomplete_buckets({
      day_parts: [DayPart]
    })
    render :json => buckets.flatten
  end

  protected

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push(label: "Status", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
      end
    end

    def collection_to_json
      collection.map{|day_part| {
        :id => day_part.id,
        :name => day_part.name,
        :description => day_part.description,
        :status => day_part.active? ? 'Active' : 'Inactive',
        :active => day_part.active?,
        :links => {
            edit: edit_day_part_path(day_part),
            show: day_part_path(day_part),
            activate: activate_day_part_path(day_part),
            deactivate: deactivate_day_part_path(day_part),
            delete: day_part_path(day_part)
        }
      }}
    end

end