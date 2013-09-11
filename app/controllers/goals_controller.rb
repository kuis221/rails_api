class GoalsController < FilteredController
  belongs_to :company_user, optional: true, polymorphic: true
  respond_to :js, only: [:create, :new, :update, :edit]
  respond_to :json, only: [:create, :update]
  actions :create, :update, :new, :edit
end