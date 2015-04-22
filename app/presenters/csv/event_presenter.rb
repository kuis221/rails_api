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
      datetime @model.start_at
    end

    def end_date
      datetime @model.end_at
    end

    def promo_hours
      number_with_precision(@model.promo_hours, precision: 2)
    end

    def place_address
      h.strip_tags(h.event_place_address(@model, false, ', ', ', '))
    end

    def place_td_linx_code
      "=\"#{@model.place_td_linx_code}\"" unless @model.place_td_linx_code.blank?
    end
  end
end
