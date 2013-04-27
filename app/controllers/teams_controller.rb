class TeamsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update]

  respond_to_datatables do
    columns [
      {:attr => :name, :column_name => 'teams.name', :value => Proc.new{|team| @controller.view_context.link_to(team.name, @controller.view_context.team_path(team)) }, :searchable => true},
      {:attr => :users_count ,:column_name => 'teams.users_count'},
      {:attr => :description ,:column_name => 'teams.description', :searchable => true},
      {:attr => :active ,:column_name => 'teams.active',  :value => Proc.new{|team| team.active? ? 'Active' : 'Inactive' } }
    ]
    @editable  = true
    @deactivable = true
  end

  def users
    @users = resource.users.active
  end

  def deactivate
    if resource.active?
      resource.deactivate
    else
      resource.activate
    end
  end

end
