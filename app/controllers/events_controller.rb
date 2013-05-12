class EventsController < InheritedResources::Base
  load_and_authorize_resource

  # This helper provide the methods to add/remove team members to the event
  include TeamMembersHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :json, only: [:index]

  has_scope :by_period, :using => [:start_date, :end_date]

  protected

    def end_of_association_chain
      super.includes([:campaign, :place])
    end

end
