module Csv
  class TaskPresenter < BasePresenter
    def due_date
      Timeliness.parse(@model.due_at, zone: 'UTC').strftime('%m/%d/%Y') if @model.due_at.present?
    end
  end
end
