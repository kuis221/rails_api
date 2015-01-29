# Custom Filters Categories Controller class
#
# This class handle the requests for managing the Custom Filters Categories
#
class CustomFiltersCategoriesController < InheritedResources::Base
  respond_to :json, only: [:default_view]
end