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
    #authorize! :split, event_expense
    parent.update_attributes(split_attributes)
    render template: 'event_expenses/create', locals: { resource: parent }
  end

  private

  def check_split_expense
    render 'split_expense' if params['commit'] == 'Split Expense'
  end

  def split_attributes
    params.require(:event).permit(event_expenses_attributes: [:expense_date, :category, :brand_id, :amount])
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
end
