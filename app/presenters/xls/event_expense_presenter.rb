module Xls
  class EventExpensePresenter < BasePresenter
    def expense_date
      return if @model.expense_date.nil?
      Timeliness.parse(@model.expense_date.strftime('%Y-%m-%d 00:00:00'), zone: 'UTC').strftime('%FT%R')
    end

    def start_date
      Timeliness.parse(@model.event.start_at.strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC').strftime('%FT%R')
    end

    def end_date
      Timeliness.parse(@model.event.end_at.strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC').strftime('%FT%R')
    end

    def event_address
      h.strip_tags(h.event_place_address(@model.event, false, ', ', ', '))
    end

    def reimbursable
      return if @model.reimbursable.nil?
      @model.reimbursable === true ? 'Yes' : 'No'
    end

    def billable
      return if @model.billable.nil?
      @model.billable === true ? 'Yes' : 'No'
    end

    def brand
      @model.brand.name if @model.brand.present?
    end
  end
end
