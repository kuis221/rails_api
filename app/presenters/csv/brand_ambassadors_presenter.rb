module Csv
  class BrandAmbassadorsPresenter < BasePresenter
    def start_date
      Timeliness.parse(@model.start_date, zone: 'UTC').strftime('%m/%d/%Y')
    end

    def end_date
      Timeliness.parse(@model.end_date, zone: 'UTC').strftime('%m/%d/%Y')
    end
  end
end
