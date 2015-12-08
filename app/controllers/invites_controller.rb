class InvitesController < InheritedResources::Base
  belongs_to :event, :venue, optional: true

  respond_to :js, only: [:new, :create, :edit, :update, :index]

  actions :new, :create, :edit, :update

  helper_method :available_campaigns, :available_events, :available_events_at_time,
                :place

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableController

  include ExportableController

  def create
    find_or_initialize_invite.save
  end

  protected

  def collection_to_csv
    CSV.generate do |csv|
      csv << ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'INVITES', 'RSVPs', 'ATTENDEES']
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
      :attendees, :rsvps_count)
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

  def available_campaigns
    view_context.allowed_campaigns(parent, conditions: ['modules like ?', "%attendance%"])
  end

  def available_events(extra_conditions = {})
    campaign_id = params[:campaign_id] || resource.event.try(:campaign_id)
    event_date = params[:date] || resource.event.try(:start_date)
    return [] unless campaign_id && event_date
    zone = Company.current.timezone_support? ? 'UTC' : :current
    start_date = Timeliness.parse("#{event_date} 00:00:00", zone: zone)
    end_date = Timeliness.parse("#{event_date} 23:59:00", zone: zone)
    prefix = Company.current.timezone_support? ? 'local_' : ''
    conditions = {
      campaign_id: campaign_id,
      "#{prefix}start_at": start_date..end_date }
    extra_conditions.each { |k, v| conditions[k] = v unless v.blank? }
    current_company.events.accessible_by_user(current_company_user).includes(:place).where(conditions)
  end

  def available_events_at_time(time)
    return available_events if time.blank?
    prefix = Company.current.timezone_support? ? 'local_' : ''
    available_events.where "#{prefix}start_at::time = ?", time
  end

  def place
    id = params[:place_id]
    return resource.event.try(:place) unless id.present?
    @place ||=
      if id.to_s =~ /^[0-9]+$/
        Place.find(id)
      else
        reference, place_id = id.split('||')
        Place.load_by_place_id(place_id, reference)
      end
  end
end
