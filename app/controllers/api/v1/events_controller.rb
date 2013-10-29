class Api::V1::EventsController < Api::V1::FilteredController

  resource_description do
    short 'Events'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
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

  api :GET, '/api/v1/events', "Search for a list of events"
  param :campaign, Array, :desc => "A list of campaign ids to filter the results"
  param :place, Array, :desc => "A list of places to filter the results"
  param :area, Array, :desc => "A list of areas to filter the results"
  param :user, Array, :desc => "A list of users to filter the results"
  param :team, Array, :desc => "A list of teams to filter the results"
  param :status, ['Active', 'Inactive'], :desc => "A list of event status to filter the results"
  param :event_status, ['Unsent', 'Submitted', 'Approved', 'Rejected', 'Late', 'Due'], :desc => "A list of event recap status to filter the results"
  param :page, :number, :desc => "The number of the page, Default: 1"
  description <<-EOS
    Returns a list of events filtered by the given params. The results are returned on groups of 30 per request. To obtain the next 30 results provide the <page> param.

    *Facets*

    Faceting is a feature of Solr that determines the number of documents that match a given search and an additional criterion

    When <page> is "1", the result will include a list of facets scoped on the following search params

    - start_date
    - end_date

    *Facets Results*

    The API returns the facets on the following format:

      [
        {
          label: String,            # Any of: Campaigns, Brands, Location, People, Active State, Event Status
          items: [                  # List of items for the facet sorted by relevance
            {
              "label": String,      # The name of the item
              "id": String,         # The id of the item, this should be used to filter the list by this items
              "name": String,       # The param name to be use for filtering the list (campaign, user, team, place, area, status, event_status)
              "count": Number,      # The number of results for this item
              "selected": Boolean   # True if the list is being filtered by this item
            },
            ....
          ],
          top_items: [              # Some facets will return this as a list of items that have the greater number of results
            <other list of items>
          ]
        }
      ]

  EOS
  def index
    collection
  end

  api :GET, '/api/v1/events/:id', 'Return a event\'s details'
  param :id, :number, required: true, desc: "Event ID"
  def show
    if resource.present?
      render
    end
  end

  api :POST, '/api/v1/events', 'Cratea a new event'
  param_group :event
  def create
    create! do |success, failure|
      success.json { render :show }
      success.xml { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  api :PUT, '/api/v1/events/:id', 'Update a event\'s details'
  param :id, :number, required: true, desc: "Event ID"
  param_group :event
  def update(active = nil)
    self.active = active unless active.nil?
    update! do |success, failure|
      success.json { render :show }
      success.xml  { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml  { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  api :GET, '/api/v1/events/:id', 'Get the list of results for the events'
  param :id, :number, required: true, desc: "Event ID"
  def results
    @results = resource.results_for(resource.campaign.form_fields)
    @results.each{|r| r.save(validate: false) if r.new_record? }
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
      params.permit({campaign: []}, {status: []}, {event_status: []})
    end

end