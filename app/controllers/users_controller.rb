class UsersController < InheritedResources::Base
  respond_to :js, only: :new

  respond_to_datatables do
    columns [
      {:attr => :first_name ,:column_name => 'users.first_name', :searchable => true},
      {:attr => :last_name ,:column_name => 'users.last_name', :searchable => true},
      {:attr => :email ,:column_name => 'users.email'}
    ]
  end

  def dashboard

  end
end
