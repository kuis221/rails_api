# Date Ranges Controller class
#
# This class handle the requests for the Date Items
#
class DateRangesController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :xls, :pdf, only: :index

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableController

  protected

  def permitted_params
    params.permit(date_range: [:description, :name])[:date_range]
  end

  def facets
    @facets ||= Array.new.tap do |f|
      f.push build_state_bucket
      f.concat build_custom_filters_bucket
    end
  end
end
