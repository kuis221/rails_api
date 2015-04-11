class InvitesController < InheritedResources::Base
  belongs_to :event, :venue, :area, optional: true

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
        if resource.venue.present?
          parent.invites.active.find_by(venue_id: invite.venue_id)
        elsif resource.area.present?
          parent.invites.active.find_by(area_id: invite.area_id)
        end
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

  def collection_to_csv
    for_event = parent.is_a?(Event)
    CSV.generate do |csv|
      cols =
        if for_event
          if export_individual?
            ['ACCOUNT']
          else
            ['MARKET']
          end
        else
          ['EVENT DATE', 'CAMPAIGN']
        end
      cols.concat ['JAMESON LOCALS', 'TOP 100'] if export_individual?
      cols.concat ['INVITES', 'RSVPs', 'ATTENDEES']
      csv << cols
      each_collection_item do |item|
        cols =
          if for_event
            if export_individual?
              [item.place_name]
            else
              [item.market]
            end
          else
            [item.event_date, item.campaign_name]
          end
        cols.concat [item.jameson_locals, item.top_venue] if export_individual?
        cols.concat [item.invitees, item.rsvps_count, item.attendees]
        csv << cols
      end
    end
  end

  def invividal_data(rsvp)
    [rsvp.registrant_id, rsvp.date_added, rsvp.email, rsvp.mobile_phone, rsvp.mobile_signup,
     rsvp.first_name, rsvp.last_name, rsvp.attended_previous_bartender_ball,
     rsvp.opt_in_to_future_communication, rsvp.primary_registrant_id, rsvp.bartender_how_long,
     rsvp.bartender_role]
  end

  def collection
    if export_individual?
      end_of_association_chain.active
    else
      end_of_association_chain.active
        .select('market, sum(attendees) attendees, sum(invitees) invitees, sum(rsvps_count) rsvps_count')
        .group('market')
    end
  end

  def export_individual?
     params[:format] == 'csv' && params[:export_mode] == 'individual'
  end

  def invite_params
    params.require(:invite).permit(:place_reference, :venue_id, :event_id, :area_id, :invitees, :attendees, :rsvps_count)
  end
end
