class RolesController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update]

  def set_permissions
    if params[:permissions]
      Role.all.each do |group|
        group.permissions = params[:permissions][group.id.to_s]
        group.save
      end
    end
  end
end
