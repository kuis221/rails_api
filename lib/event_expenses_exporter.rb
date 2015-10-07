class EventExpensesExporter < BaseExporter
  def initialize(company_user, params)
    @company_user = company_user
    @params = params
  end

  def expenses_columns
    ['SPENT'].concat categories
  end

  def event_expenses(event)
    @event_expense_scope ||= EventExpense.group('UPPER(category)')
    values @event_expense_scope.where(event_id: event.id).sum('amount')
  end

  def categories
    @categories ||= begin
      scope = EventExpense.joins(:event).where(events: { company_id: @company_user.company_id })
      scope = scope.where(events: { campaign_id: campaign_ids }) if campaign_ids.any?
      scope.order('1 ASC').pluck('DISTINCT(UPPER(category))')
    end
  end

  def values(expenses)
    return [0] if categories.empty?
    @columns_hash ||= Hash[categories.map { |c| [c, nil] }]

    # Clear hash of values
    @columns_hash.each { |k, _| @columns_hash[k] = nil }
    expenses.each { |k, v| @columns_hash[k] = v if @columns_hash.key?(k) }
    values = @columns_hash.values
    [values.reject(&:blank?).inject(0, :+)].concat values
  end
end
