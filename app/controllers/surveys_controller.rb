class SurveysController < FilteredController
  belongs_to :event
  respond_to :js, only: [:new, :create, :edit, :update]
  actions :new, :create, :edit, :update
end