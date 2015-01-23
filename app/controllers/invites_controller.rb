class InvitesController < InheritedResources::Base
  belongs_to :event, :venue, optional: true

  respond_to :js, only: [:new, :create, :edit, :update]

  actions :new, :create, :edit, :update

  helper_method :parent_activities

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  protected

  def invite_params
    params.require(:invite).permit(:place_reference, :venue_id, :event_id, :invitees, :attendees, :rsvps_count)
  end

  def parent_activities
    parent.activities.active + parent.invites.active
  end
end
