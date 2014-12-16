# Activity Types Controller class
#
# This class handle the requests for managing the Activity Types
class ActivityTypesController < FilteredController
  before_action :load_campaign, only: [:set_goal]
  respond_to :js, only: [:new, :create, :edit, :update, :set_goal]
  respond_to :json, only: [:show, :update]
  respond_to :xls, :pdf, only: :index
  belongs_to :company, :campaign, optional: true

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  # This helper provide the methods to export HTML to PDF
  extend ExportableFormHelper

  def load_campaign
    @campaign = current_company.campaigns.find(params[:campaign_id])
  end

  def autocomplete
    buckets = autocomplete_buckets(
      activity_types: [ActivityType],
      active_state: []
    )
    render json: buckets.flatten
  end

  def update
    update! do |success, failure|
      success.js { render }
      success.json { render json: { result: 'OK' } }
      failure.json do
        render json: { result: 'KO', message: resource.errors.full_messages.join('<br />') }
      end
    end
  end

  def set_goal
    @activity_type = ActivityType.find(params[:activity_type_id])
  end

  protected

  # This is used for exporting the form in PDF format. Initializes
  # a new activity for the current activity type
  def fieldable
    @fieldable ||= resource.activities.build(
      activitable: resource.company.events.build(
        start_date: Date.current.to_s(:slashes),
        start_time: '08:00 PM',
        end_date: Date.current.to_s(:slashes),
        end_time: '11:30 PM',
        place: Place.new(name: 'Bar None', route: 'Union Street',
                         street_number: '5555', city: 'San Francisco',
                         state: 'California', country: 'US', zipcode: '94110')
      ),
      activity_date: '  '
    )
    @fieldable.activity_date = nil
    @fieldable
  end

  def pdf_form_file_name
    "#{resource.name.parameterize}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  def permitted_params
    params.permit(activity_type: [
      :name, :description,
      { form_fields_attributes: [
        :id, :name, :field_type, :ordering, :required, :_destroy,
        { settings: [:description, :range_min, :range_max, :range_format] },
        { options_attributes: [:id, :name, :_destroy, :ordering] },
        { statements_attributes: [:id, :name, :_destroy, :ordering] }] },
      { goals_attributes: [
        :id, :goalable_id, :goalable_type, :activity_type_id, :value, value: []] }
    ])[:activity_type]
  end
end
