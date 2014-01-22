class ContactEventsController < InheritedResources::Base

  belongs_to :event

  actions :new, :create, :destroy, :update, :edit

  custom_actions collection: [:add, :list]

  defaults :resource_class => ContactEvent

  load_and_authorize_resource

  respond_to :js

  def add
  end

  def list
    @contacts = ContactEvent.contactables_for_event(parent, params[:term])
    render layout: false
  end

  protected
    def build_resource(*args)
      @contact_event ||= super
      @contact_event.build_contactable if action_name == 'new' && @contact_event.contactable.nil?
      @contact_event
    end

    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      params.permit(contact_event: [:id, :contactable_id, :contactable_type, {contactable_attributes: [:id, :street1, :street2, :city, :company_id, :country, :email, :first_name, :last_name, :phone_number, :state, :title, :zip_code]}])[:contact_event]
    end

    def modal_dialog_title
      I18n.translate("modals.title.#{resource.contactable.new_record? ? 'new' : 'edit'}.#{resource.class.name.underscore.downcase}")
    end
end
