class UsersController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update]

  custom_actions :resource => :deactivate

  respond_to_datatables do
    columns [
      {:attr => :first_name ,:column_name => 'users.first_name', :searchable => true},
      {:attr => :last_name ,:column_name => 'users.last_name', :searchable => true},
      {:attr => :email ,:column_name => 'users.email'}
    ]
    @editable  = true
    @deactivable = true
  end

  def deactivate
    if resource.active?
      resource.deactivate!
    else
      resource.activate!
    end
  end

  def dashboard

  end
end
