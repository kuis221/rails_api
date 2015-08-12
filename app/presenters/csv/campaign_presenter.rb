module Csv
  class CampaignPresenter < BasePresenter
    def first_event_date
      Timeliness.parse(@model.first_event_at, zone: 'UTC').strftime('%m/%d/%Y %R') if @model.first_event_at.present?
    end

    def last_event_date
      Timeliness.parse(@model.last_event_at, zone: 'UTC').strftime('%m/%d/%Y %R') if @model.last_event_at.present?
    end
  end
end
