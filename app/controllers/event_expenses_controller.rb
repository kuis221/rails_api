# Event Expenses Controller class
#
# This class handle the requests for the Event Expenses
#
class EventExpensesController < InheritedResources::Base
  respond_to :js

  belongs_to :event

  load_resource :event
  load_and_authorize_resource through: :event

  helper_method :expense_categories

  private

  def expense_categories
    resource.event.campaign.expense_categories
  end

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    params.permit(
      event_expense: [
        :category, :amount, :brand_id, :expense_date, :reimbursable,
        :billable, :merchant, :description,
        { receipt_attributes: [:id, :direct_upload_url, :_destroy] }]
    )[:event_expense]
  end
end
