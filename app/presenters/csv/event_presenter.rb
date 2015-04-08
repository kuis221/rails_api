module Csv
  class EventPresenter < BasePresenter
    def contacts
      @model.contact_events.map(&:full_name).sort.join(', ')
    end

    def team_members
      ActiveRecord::Base.connection.unprepared_statement do
        ActiveRecord::Base.connection.select_values("
          #{@model.users.joins(:user).select('users.first_name || \' \' || users.last_name AS name').reorder(nil).to_sql}
          UNION ALL
          #{@model.teams.select('teams.name').reorder(nil).to_sql}
          ORDER BY name
        ").join(', ')
      end
    end

    def url
      h.event_url(@model)
    end

    def start_date
      Timeliness.parse(@model.start_at.strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC').strftime('%FT%R')
    end

    def end_date
      Timeliness.parse(@model.end_at.strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC').strftime('%FT%R')
    end

    def promo_hours
      number_with_precision(@model.promo_hours, precision: 2)
    end

    def place_address
      h.strip_tags(h.event_place_address(@model, false, ', ', ', '))
    end
  end
end
