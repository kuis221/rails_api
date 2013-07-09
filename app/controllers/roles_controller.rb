class RolesController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def set_permissions
    if params[:permissions]
      Role.all.each do |group|
        group.permissions = params[:permissions][group.id.to_s]
        group.save
      end
    end
  end

  def autocomplete
    buckets = autocomplete_buckets({
      roles: [Role]
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
      collection.map{|role| {
        :id => role.id,
        :name => role.name,
        :description => role.description,
        :status => role.status,
        :active => role.active?,
        :links => {
            edit: edit_role_path(role),
            show: role_path(role),
            activate: activate_role_path(role),
            deactivate: deactivate_role_path(role)
        }
      }}
    end
end
