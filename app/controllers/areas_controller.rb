class AreasController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  custom_actions member: [:select_places, :add_places]

  load_and_authorize_resource except: :index

  def autocomplete
    buckets = autocomplete_buckets({
      areas: [Area]
    })
    render :json => buckets.flatten
  end

  private

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        facet_params = HashWithIndifferentAccess.new(search_params.select{|k, v| [:q, :company_id].include?(k.to_sym)})
        facet_search = resource_class.do_search(facet_params, true)

        f.push(label: "Status", items: facet_search.facet(:status).rows.map{|x| build_facet_item({label: x.value, id: x.value, name: :status, count: x.count}) })
      end
    end

    def collection_to_json
      collection.map{|area| {
        :id => area.id,
        :name => area.name,
        :description => area.description,
        :status => area.status,
        :active => area.active?,
        :links => {
            edit: edit_area_path(area),
            show: area_path(area),
            activate: activate_area_path(area),
            deactivate: deactivate_area_path(area)
        }
      }}
    end

end