module Csv
  class InvitePresenter < BasePresenter
    def jameson_locals
      @model.jameson_locals? ? 'YES' : 'NO'
    end

    def top_venue
      @model.top_venue? ? 'YES' : 'NO'
    end

    def event_date
      datetime @model.event.start_at
    end
  end
end
