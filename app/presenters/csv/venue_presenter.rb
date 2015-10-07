module Csv
  class VenuePresenter < BasePresenter
    def td_linx_code
      @model.td_linx_code if @model.td_linx_code =~ /^[0-9]+$/
    end

    def score
      @model.score.blank? ? 0 : @model.score
    end

    def spent
      number_to_currency(@model.spent, precision: 2)
    end
  end
end
