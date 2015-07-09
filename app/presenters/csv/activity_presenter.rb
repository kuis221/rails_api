module Csv
  class ActivityPresenter < BasePresenter
    def date
      Timeliness.parse(@model.activity_date.strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC').strftime('%F')
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

    def created_at
      datetime @model.created_at if @model.created_at.present?
    end

    def created_by
      if (author = @model.created_by).present?
        author.full_name
      end
    end

    def last_modified
      datetime @model.updated_at if @model.updated_at.present?
    end

    def modified_by
      if (author = @model.updated_by).present?
        author.full_name
      end
    end
  end
end
