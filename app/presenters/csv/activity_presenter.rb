module Csv
  class ActivityPresenter < BasePresenter
    def date
      Timeliness.parse(@model.activity_date.strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC').strftime('%FT%R')
    end

    def place_address
      h.strip_tags(h.event_place_address(@model, false, ', ', ', '))
    end
  end
end
