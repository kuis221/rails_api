class Api::V1::EventsController < Api::V1::FilteredController

  resource_description do
    short 'Events'
    formats ['json', 'xml']
    error 404, "Missing"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true
    param :company_id, :number, required: true
    description <<-EOS

    EOS
  end

  def_param_group :event do
    param :event, Hash, :action_aware => true do
      param :campaign_id, :number, required: true, desc: "Campaign ID"
      param :start_date, String, required: true, desc: "Event's start date"
      param :end_date, String, required: true, desc: "Event's end date"
      param :start_time, String, required: true, desc: "Event's start time'"
      param :end_time, String, required: true, desc: "Event's end time"
      param :place_reference, :number, required: false, desc: "Event's place ID"
      param :active, String, desc: "Event's status"
    end
  end

  api :GET, '/api/v1/events'
  param :campaign, Array
  def index
    collection
  end

  api :GET, '/api/v1/events/:id'
  param :id, :number, required: true, desc: "Event ID"
  def show
    if resource.present?
      render
    end
  end

  api :POST, '/api/v1/events'
  param_group :event
  def create
    create! do |success, failure|
      success.json { render :show }
      success.xml { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  api :PUT, '/api/v1/events/:id'
  param :id, :number, required: true, desc: "Event ID"
  param_group :event
  def update(active = nil)
    self.active = active unless active.nil?
    update! do |success, failure|
      success.json { render :show }
      success.xml { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  protected

    def permitted_params
      parameters = {}
      allowed = []
      allowed += [:end_date, :end_time, :start_date, :start_time, :campaign_id, :active, :place_id, :place_reference] if can?(:update, Event) || can?(:create, Event)
      allowed += [:summary, {results_attributes: [:form_field_id, :kpi_id, :kpis_segment_id, :value, :id]}] if can?(:edit_data, Event)
      parameters = params.require(:event).permit(*allowed)
      parameters
    end

    def permitted_search_params
      params.permit({campaign: []})
    end

end