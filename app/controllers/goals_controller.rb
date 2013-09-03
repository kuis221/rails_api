class GoalsController < FilteredController
  respond_to :json, only: [:create, :update]
  actions :create, :update
end