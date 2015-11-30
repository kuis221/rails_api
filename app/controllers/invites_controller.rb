class InvitesController < InheritedResources::Base
  belongs_to :event, :venue, :area, optional: true

  respond_to :js, only: [:new, :create, :edit, :update, :index]

  actions :new, :create, :edit, :update

  helper_method :parent_activities

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableController

  include ExportableController

  def create
    find_or_initialize_invite.save
  end

  protected

  def collection_to_csv
    CSV.generate do |csv|
      csv << ['VENUE' 'EVENT DATE', 'CAMPAIGN', 'INVITES', 'RSVPs', 'ATTENDEES']
      each_collection_item do |item|
        csv << [item.place_name, item.event_date, item.campaign_name, item.invitees, item.rsvps_count, item.attendees]
      end
    end
  end

  def collection
    end_of_association_chain.active
  end

  def invite_params
    @invite_params ||= params.require(:invite).permit(
      :place_reference, :venue_id, :event_id, :invitees,
      :attendees, :rsvps_count).tap do |p|
#       if p[:individuals_attributes] && p[:individuals_attributes].any?
#         p[:invitees] ||= p[:invitees].to_i +  p[:individuals_attributes].count
#       end
    end
  end

  # Checks if there is already in invitation on this venue and use that
  # otherwise initialize a new one.
  def find_or_initialize_invite
    invite = build_resource
    found_invite =
      if parent.is_a?(Event)
        if invite.venue.present?
          parent.invites.active.find_by(venue_id: invite.venue_id)
        end
      else
        parent.invites.active.find_by(event_id: invite.event_id)
      end
    return invite unless found_invite.present?
    invite_params[:invitees] = found_invite.invitees + invite.invitees.to_i
    found_invite.assign_attributes invite_params
    found_invite
  end
end
