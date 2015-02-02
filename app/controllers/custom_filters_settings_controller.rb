# Custom Filters Settings Controller class
#
# This class handle the requests for managing the Custom Filters Settings
#
class CustomFiltersSettingsController < InheritedResources::Base
  
  respond_to :js, only: [:index]
  
  actions :index

  def index
  end
end