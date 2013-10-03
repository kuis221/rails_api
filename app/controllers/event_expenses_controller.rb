class EventExpensesController < InheritedResources::Base
  respond_to :js

  belongs_to :event

  load_resource :event
  load_and_authorize_resource through: :event

  private
    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      params.permit(event_expense: [:amount, :file, :name])[:event_expense]
    end
end
