class DayItemsController < FilteredController
  belongs_to :day_part
  respond_to :js, only: [:new, :create, :update, :destroy]

  actions :all, :except => [:show, :edit, :index]
end
