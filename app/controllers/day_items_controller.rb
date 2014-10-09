# Day Items Controller class
#
# This class handle the requests for the Day Items
#
class DayItemsController < FilteredController
  belongs_to :day_part
  respond_to :js, only: [:new, :create, :update, :destroy]

  actions :all, except: [:show, :edit, :index]

  skip_authorize_resource
  before_action :edit_authorize_parent

  private

  def permitted_params
    params.permit(day_item: [:start_time, :end_time])[:day_item]
  end

  def edit_authorize_parent
    authorize! :edit, parent
  end
end
