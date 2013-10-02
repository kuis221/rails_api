class DayItemsController < FilteredController
  belongs_to :day_part
  respond_to :js, only: [:new, :create, :update, :destroy]

  actions :all, :except => [:show, :edit, :index]

  private
    def permitted_params
      params.permit(day_item: [:start_time, :end_time])[:day_item]
    end
end
