class UsersController < InheritedResources::Base
  respond_to :json, only: :index

  respond_to_datatables do
    columns [
      {:name => 'first_name' ,:sort => 'users.first_name'},
      {:name => 'last_name' ,:sort => 'users.last_name'},
      {:name => 'email' ,:sort => 'users.email'}
    ]
  end
end
