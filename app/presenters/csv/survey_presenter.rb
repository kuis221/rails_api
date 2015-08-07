module Csv
  class SurveyPresenter < BasePresenter
    def place_address(event)
      h.strip_tags(h.event_place_address(event, false, ', ', ', '))
    end

    def event_start_date
      Timeliness.parse(h.event_date(event, :start_at), zone: 'UTC').strftime('%m/%d/%Y %I:%M%p')
    end

    def event_end_date
      Timeliness.parse(h.event_date(event, :end_at), zone: 'UTC').strftime('%m/%d/%Y %I:%M%p')
    end

    def created_date
      Timeliness.parse(@model.created_at, zone: 'UTC').strftime('%m/%d/%Y %I:%M%p')
    end
  end
end