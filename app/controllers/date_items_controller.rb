class DateItemsController < FilteredController
  belongs_to :date_range
  respond_to :js, only: [:new, :create, :edit, :update, :destroy]

  authorize_resource

  protected

    def sort_options
      {
        'name' => { :order => 'date_items.start_date' }
      }
    end

    def build_resource(*args)
      @date ||= super
      @date.recurrence_type ||= 'daily'
      @date.recurrence_period ||= 1
      @date
    end
end
