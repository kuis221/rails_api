# Event Expenses Controller class
#
# This class handle the requests for the Event Expenses
#
class EventExpensesController < InheritedResources::Base
  respond_to :js

  belongs_to :event

  load_resource :event
  load_and_authorize_resource through: :event, except: [:split]

  helper_method :expense_categories

  before_action :check_split_expense, only: [:update, :create]

  def split
    load_resource_from_split_params
    authorize! :split, resource
    parent.update_attributes(split_attributes)
    render :create
  end

  private

  def check_split_expense
    return unless params['commit'] == 'Split Expense'
    render 'split_expense'
  end

  def split_attributes
    params.require(:event).permit(
      event_expenses_attributes: [
        :id, :expense_date, :category, :brand_id, :amount, :_destroy])
  end

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

  def load_resource_from_split_params
    @event_expense =
      if params[:id].present?
        parent.event_expenses.find(params[:id])
      else
        EventExpense.new(event: parent)
      end
  end
end
