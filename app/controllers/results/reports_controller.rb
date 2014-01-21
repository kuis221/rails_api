class Results::ReportsController < InheritedResources::Base
  respond_to :js, only: [:new, :create]
  def index
  end
end
