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
      p = params.dup
      p[:event_expense] ||= {}
      p[:event_expense][:name] = params[:name]
      p[:event_expense][:amount] = params[:amount]

      p = p.permit(event_expense: [:amount, {receipt_attributes:[:direct_upload_url]}, :name])[:event_expense]

    end
end
