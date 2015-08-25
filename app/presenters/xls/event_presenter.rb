module Xls
  class EventPresenter < Csv::EventPresenter
    def start_date
      Timeliness.parse(@model.start_at.strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC').strftime('%FT%R')
    end

    def end_date
      Timeliness.parse(@model.end_at.strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC').strftime('%FT%R')
    end
  end
end
