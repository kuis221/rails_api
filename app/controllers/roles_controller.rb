class RolesController < FilteredController
  authorize_resource

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update]

  has_scope :with_text

  def set_permissions
    if params[:permissions]
      Role.all.each do |group|
        group.permissions = params[:permissions][group.id.to_s]
        group.save
      end
    end
  end

  protected
    def collection_to_json
      collection.map{|role| {
        :id => role.id,
        :name => role.name,
        :description => role.description,
        :status => role.active? ? 'Active' : 'Inactive',
        :active => role.active?,
        :links => {
            edit: edit_role_path(role),
            show: role_path(role),
            activate: activate_role_path(role),
            deactivate: deactivate_role_path(role)
        }
      }}
    end

    def sort_options
      {
        'name' => { :order => 'roles.name' },
        'description' => { :order => 'roles.description' },
        'active' => { :order => 'roles.active' }
      }
    end
end
