# Event Expenses Controller class
#
# This class handle the requests for the Event Expenses
#
class EventExpensesController < InheritedResources::Base
  respond_to :js

  belongs_to :event

  load_resource :event
  load_and_authorize_resource through: :event

  def new
    return true unless parent.campaign.range_module_settings?('expenses')
    max = parent.campaign.module_setting('expenses', 'range_max')
    resource.errors.add(:base, I18n.translate('instructive_messages.execute.expense.add_exceeded.new', expenses_max: max)) if parent.event_expenses.count >= max.to_i
  end

  private

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    params.permit(
      event_expense: [
        :name, :amount, :brand_id, { receipt_attributes: [:id, :direct_upload_url, :_destroy] }]
    )[:event_expense]
  end
end
