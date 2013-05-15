class RolesController < InheritedResources::Base
  load_and_authorize_resource

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update]

  respond_to_datatables do
    columns [
      {:attr => :name, :column_name => 'roles.name', :searchable => true},
      {:attr => :description, :column_name => 'roles.description', :searchable => true},
      {:attr => :active ,:column_name => 'roles.active', :value => Proc.new{|role| role.active? ? 'Active' : 'Inactive' } }
    ]
    @editable  = true
    @deactivable = true
  end

  def set_permissions
    if params[:permissions]
      Role.all.each do |group|
        group.permissions = params[:permissions][group.id.to_s]
        group.save
      end
    end
  end
end
