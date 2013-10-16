class ContactEventsController < InheritedResources::Base

  belongs_to :event

  actions :new, :create, :destroy

  custom_actions collection: [:add]

  defaults :resource_class => ContactEvent

  respond_to :js

  def add
    @contacts = current_company.contacts
  end

  protected
    def build_resource(*args)
      @contact_event ||= super
      @contact_event.build_contact if @contact_event.contact.nil?
      @contact_event
    end

    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      params.permit(contact_event: [:contact_id, {contact_attributes: [:street1, :street2, :city, :company_id, :country, :email, :first_name, :last_name, :phone_number, :state, :title, :zip_code]}])[:contact_event]
    end
end
