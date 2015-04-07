module Csv
  class ActivityPresenter < BasePresenter
    def date
      Timeliness.parse(@model.activity_date.strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC').strftime('%F')
    end

    def place_address
      h.strip_tags(h.event_place_address(@model, false, ', ', ', '))
    end

    def place_td_linx_code
      "=\"#{@model.place_td_linx_code}\"" unless @model.place_td_linx_code.blank?
    end
  end
end
