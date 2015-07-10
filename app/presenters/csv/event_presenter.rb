module Csv
  class EventPresenter < BasePresenter
    def contacts
      @model.contact_events.map(&:full_name).sort.join(', ')
    end

    def team_members
      @model.event_team_members
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

    def approved_date
      datetime @model.approved_at if @model.approved_at.present?
    end

    def submitted_date
      datetime @model.submitted_at if @model.submitted_at.present?
    end

    def created_at
      datetime @model.custom_created_at if @model.custom_created_at.present?
    end

    def created_by
      if (created_by = @model.custom_created_by).present?
        created_by.full_name
      end
    end

    def last_modified
      datetime @model.custom_updated_at if @model.custom_updated_at.present?
    end

    def modified_by
      if (updated_by = @model.custom_updated_by).present?
        updated_by.full_name
      end
    end

    def promo_hours
      number_with_precision(@model.promo_hours, precision: 2)
    end

    def place_address
      h.strip_tags(h.event_place_address(@model, false, ', ', ', '))
    end

    def country
      @model.place_country
    end

    def place_td_linx_code
      "=\"#{@model.place_td_linx_code}\"" unless @model.place_td_linx_code.blank?
    end
  end
end
