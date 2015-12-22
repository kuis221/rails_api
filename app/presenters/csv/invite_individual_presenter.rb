module Csv
  class InviteIndividualPresenter < InvitePresenter
    def rsvpd
      @model.rsvpd? ? 'YES' : 'NO'
    end

    def attended
      @model.attended? ? 'YES' : 'NO'
    end
  end
end
