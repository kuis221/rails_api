# Activities Controller class
#
# This class handle the requests for managing the Activities
class ActivitiesController < FilteredController
  belongs_to :venue, :event, polymorphic: true, optional: true
  respond_to :js, only: [:new]
  custom_actions member: [:form]

  layout 'empty', except: :show

  # This helper provide the methods to export HTML to PDF
  extend ExportableFormHelper

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  helper_method :assignable_users, :activity_types

  def new
    if params[:activity] && params[:activity][:activity_type_id] == 'attendance'
      @invite = parent.invites.build
      render 'invitation_form'
    elsif params[:activity] && params[:activity][:activity_type_id]
      build_resource
      @brands = Brand.accessible_by_user(current_company_user).order(:name)
    elsif request.format.js?
      render partial: 'form_dialog', locals: { form_partial: 'select_activity_type_form' }
    end
  end

  def thanks
    if params[:activity_type_id] == 'attendance'
      @activity_type = OpenStruct.new(id: params[:activity_type_id], name: 'Invitation')
    else
      @activity_type = current_company.activity_types.find(params[:activity_type_id])
    end
  end

  def create
    create! do |success, failure|
      success.html do
        flash.clear
        redirect_to url_for(action: :thanks, activity_type_id: resource.activity_type_id)
      end
    end
  end

  def update
    update! do |success, failure|
      success.html do
        flash.clear
        redirect_to url_for(resource.activitable) + '#activities-list'
      end
    end
  end

  protected

  def pdf_form_file_name
    "#{resource.activity_type_name.parameterize}-#{Time.now.strftime('%Y%m%d%H%M%S')}.pdf"
  end

  def assignable_users
    current_company.company_users.active.for_dropdown
  end

  def activity_types
    types =
      if parent.is_a?(Event)
        parent.campaign.activity_types.order('activity_types.name ASC')
      else
        current_company.activity_types.active.order(:name)
      end.pluck(:name, :id)

    return types unless can?(:create_invite, parent) &&
                        ((parent.is_a?(Event) && parent.campaign.enabled_modules.include?('attendance')) ||
                         parent.is_a?(Venue))

    types.push %w(Invitation attendance)

    types.sort { |a, b| a[0] <=> b[0] }
  end

  # Because there is no collection path, try to return a path
  # based on the current activity or the events_path
  def collection_path
    if params[:id].present?
      url_for(resource.activitable)
    else
      events_path
    end
  end

  def permitted_params
    params.permit(activity: [
      :activity_type_id, {
        results_attributes: [:id, :form_field_id, :value, { value: [] }, :_destroy] },
      :campaign_id, :company_user_id, :activity_date])[:activity].tap do |whielisted|
      unless whielisted.nil? || whielisted[:results_attributes].nil?
        whielisted[:results_attributes].each do |k, value|
          value[:value] = params[:activity][:results_attributes][k][:value]
        end
      end
    end
  end
end
