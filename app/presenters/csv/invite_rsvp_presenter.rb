module Csv
  class InviteIndividualPresenter < InvitePresenter
    def opt_in_to_future_communication
      @model.opt_in_to_future_communication? ? 'YES' : 'NO'
    end

    def mobile_signup
      @model.mobile_signup? ? 'YES' : 'NO'
    end
  end
end
