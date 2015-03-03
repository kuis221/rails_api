class InvitesController < InheritedResources::Base
  belongs_to :event, :venue, optional: true

  respond_to :js, only: [:new, :create, :edit, :update]

  actions :new, :create, :edit, :update

  helper_method :parent_activities

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  include ExportableController

  def create
    invite = build_resource
    existing_invite =
      if parent.is_a?(Event)
        parent.invites.active.find_by(venue_id: invite.venue_id) if invite.venue_id
      else
        parent.invites.active.find_by(event_id: invite.event_id)
      end
    result =
      if existing_invite.present?
        existing_invite.invitees = invite.invitees.to_i + existing_invite.invitees.to_i
        existing_invite.save
      else
        invite.save
      end
  end

  protected

  def collection
    end_of_association_chain.active
  end

  def invite_params
    params.require(:invite).permit(:place_reference, :venue_id, :event_id, :invitees, :attendees, :rsvps_count)
  end
end
