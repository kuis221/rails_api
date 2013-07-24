class DateItemsController < FilteredController
  belongs_to :date_range
  respond_to :js, only: [:new, :create, :destroy]
  actions :new, :create, :destroy

  authorize_resource

  protected

    def build_resource(*args)
      @date ||= super
      @date.recurrence_type ||= 'daily'
      @date.recurrence_period ||= 1
      @date
    end
end
