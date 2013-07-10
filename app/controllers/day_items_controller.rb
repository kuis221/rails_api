class DayItemsController < FilteredController
  belongs_to :day_part
  respond_to :js, only: [:new, :create, :edit, :update, :destroy]

  authorize_resource

  protected

    def sort_options
      {
        'name' => { :order => 'day_items.start_time' }
      }
    end
end
