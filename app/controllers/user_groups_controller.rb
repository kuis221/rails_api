class UserGroupsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update]

end
