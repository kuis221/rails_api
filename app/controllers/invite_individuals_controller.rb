class InviteIndividualsController < InheritedResources::Base
  belongs_to :event, :venue, :area, optional: true

  respond_to :js, only: [:create, :edit, :update, :index]

  actions :new, :create, :edit, :update

  helper_method :parent_activities

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableController

  include ExportableController

  protected

  def collection_to_csv
    CSV.generate do |csv|
      csv << ['VENUE', 'EVENT DATE', 'CAMPAIGN', 'NAME', 'EMAIL', 'RSVP\'d', 'ATTENDED']
      each_collection_item do |item|
        csv << [item.place_name, item.event_date, item.campaign_name, item.name, item.email, item.rsvpd, item.attended]
      end
    end
  end

  def collection
    end_of_association_chain.active
  end

  def invite_individual_params
    @invite_individual_params ||= params.require(:invite_individual).permit(
      :first_name, :last_name, :email, :rsvpd, :attended, invite_attributes: [
        :place_reference, :invitees]).tap do |p|
          next unless p.key?(:invite_attributes)
          # set the parent's id
          p[:invite_attributes]["#{parent.class.name.underscore}_id"]  = parent.id
          # set the invite id if there is already and invitation for that venue
          place_id = p[:invite_attributes][:place_reference]
          next unless place_id =~ /\A[0-9]+\z/
          invite_id = parent.invites.joins(:place).where(venues: { place_id: place_id }).first.try(:id)
          next unless invite_id.present?
          p.delete(:invite_attributes)
          p[:invite_id] = invite_id
    end
  end
end
