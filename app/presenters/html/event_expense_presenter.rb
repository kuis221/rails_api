module Html
  class EventExpensePresenter < BasePresenter
    def expense_date
      return unless @model.expense_date.present?
      @model.expense_date.to_s(:slashes)
    end

    def amount
      return unless @model.amount.present?
      number_to_currency(@model.amount, precision: 2)
    end

    def brand_name
      brand.name if @model.brand.present?
    end
  end
end
