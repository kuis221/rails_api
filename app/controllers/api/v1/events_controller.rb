class Api::V1::EventsController < Api::V1::FilteredController

  resource_description do
    short 'Events'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true
    param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the "
    description <<-EOS

    EOS
  end

  def_param_group :event do
    param :event, Hash, required: true, :action_aware => true do
      param :campaign_id, :number, required: true, desc: "Campaign ID"
      param :start_date, String, required: true, desc: "Event's start date"
      param :end_date, String, required: true, desc: "Event's end date"
      param :start_time, String, required: true, desc: "Event's start time'"
      param :end_time, String, required: true, desc: "Event's end time"
      param :place_reference, String, required: false, desc: "Event's Place ID. This can be either an existing place id that is already registered on the application, or the combination of the place reference + place id returned by Google's places API. (See: https://developers.google.com/places/documentation/details). Those two values must be concatenated by '||' in the form of '<reference>||<place_id>'"
      param :active, String, desc: "Event's status"
      param :results_attributes, :event_result, required: false, desc: "A list of event results with the id and value. Eg: results_attributes: [{id: 1, value:'Some value'}, {id: 2, value: '123'}]"
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
  see "users#companies", "User companies"

  description <<-EOS
    Returns a list of events filtered by the given params. The results are returned on groups of 30 per request. To obtain the next 30 results provide the <page> param.

    All the times and dates are returned on the user's timezone.

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

  example <<-EOS
  {
      "page": 1,
      "total": 7238,
      "facets": [
          <HERE GOES THE LIST FACETS DESCRIBED ABOVE>
      ],
      "results": [
          {
              "id": 5486,
              "start_date": "05/24/2014",
              "start_time": " 9:00 PM",
              "end_date": "05/24/2014",
              "end_time": "10:00 PM",
              "status": "Active",
              "event_status": "Unsent",
              "place": {
                  "id": 2624,
                  "name": "Kelly's Pub Too",
                  "latitude": 39.7924104,
                  "longitude": -86.2514126,
                  "formatted_address": "5341 W. 10th Street, Indianapolis, IN 46224",
                  "country": "US",
                  "state": "Indiana",
                  "state_name": "Indiana",
                  "city": "Indianapolis",
                  "route": "5341 W. 10th Street",
                  "street_number": null,
                  "zipcode": "46224"
              },
              "campaign": {
                  "id": 33,
                  "name": "Kahlua Midnight FY14"
              }
          },
          {
              "id": 5199,
              "start_date": "05/03/2014",
              "start_time": " 7:30 PM",
              "end_date": "05/03/2014",
              "end_time": " 8:30 PM",
              "status": "Active",
              "event_status": "Unsent",
              "place": {
                  "id": 2587,
                  "name": "8 Seconds Saloon",
                  "latitude": 39.767723,
                  "longitude": -86.24897,
                  "formatted_address": "111 North Lynhurst Drive, Indianapolis, IN, United States",
                  "country": "US",
                  "state": "Indiana",
                  "state_name": "Indiana",
                  "city": "Indianapolis",
                  "route": "North Lynhurst Drive",
                  "street_number": "111",
                  "zipcode": "46224"
              },
              "campaign": {
                  "id": 33,
                  "name": "Kahlua Midnight FY14"
              }
          },
          ....
      ]
  }
  EOS
  def index
    collection
  end

  api :GET, '/api/v1/events/:id', 'Return a event\'s details'
  param :id, :number, required: true, desc: "Event ID"

  example <<-EOS
  {
      "id": 5486,
      "start_date": "05/24/2014",
      "start_time": " 9:00 PM",
      "end_date": "05/24/2014",
      "end_time": "10:00 PM",
      "status": "Active",
      "event_status": "Unsent",
      "place": {
          "id": 2624,
          "name": "Kelly's Pub Too",
          "latitude": 39.7924104,
          "longitude": -86.2514126,
          "formatted_address": "5341 W. 10th Street, Indianapolis, IN 46224",
          "country": "US",
          "state": "Indiana",
          "state_name": "Indiana",
          "city": "Indianapolis",
          "route": "5341 W. 10th Street",
          "street_number": null,
          "zipcode": "46224"
      },
      "campaign": {
          "id": 33,
          "name": "Kahlua Midnight FY14"
      }
  }
  EOS
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

  api :GET, '/api/v1/events/:id/results', 'Get the list of results for the events'
  param :id, :number, required: true, desc: "Event ID"
  description <<-EOS
  Returns a list of form fields based on the event's campaign.
  EOS
  example  <<-EOS
    [
        {
            "id": 80,
            "value": "5",
            "name": "Impressions",
            "group": null,
            "ordering": 2,
            "field_type": "number",
            "options": {
                "capture_mechanism": "integer",
                "predefined_value": "",
                "required": "true"
            }
        },
        {
            "id": 82,
            "value": "45",
            "name": "Interactions",
            "group": null,
            "ordering": 3,
            "field_type": "number",
            "options": {
                "capture_mechanism": "integer",
                "predefined_value": "",
                "required": "true"
            }
        },
        {
            "id": 83,
            "value": "34",
            "name": "Samples",
            "group": null,
            "ordering": 4,
            "field_type": "number",
            "options": {
                "capture_mechanism": "integer",
                "predefined_value": "",
                "required": "true"
            }
        },
        {
            "id": 84,
            "value": "30",
            "name": "Female",
            "group": "Gender",
            "ordering": 5,
            "field_type": "percentage",
            "options": {
                "capture_mechanism": "integer"
            }
        },
        {
            "id": 85,
            "value": "70",
            "name": "Male",
            "group": "Gender",
            "ordering": 5,
            "field_type": "percentage",
            "options": {
                "capture_mechanism": "integer"
            }
        },
        {
            "id": 86,
            "value": "",
            "name": "< 12",
            "group": "Age",
            "ordering": 6,
            "field_type": "percentage",
            "options": {
                "capture_mechanism": "integer"
            }
        },
        {
            "id": 87,
            "value": "",
            "name": "12 – 17",
            "group": "Age",
            "ordering": 6,
            "field_type": "percentage",
            "options": {
                "capture_mechanism": "integer"
            }
        },
        {
            "id": 88,
            "value": "50",
            "name": "18 – 24",
            "group": "Age",
            "ordering": 6,
            "field_type": "percentage",
            "options": {
                "capture_mechanism": "integer"
            }
        },
        {
            "id": 89,
            "value": "50",
            "name": "25 – 34",
            "group": "Age",
            "ordering": 6,
            "field_type": "percentage",
            "options": {
                "capture_mechanism": "integer"
            }
        },
        {
            "id": 90,
            "value": "",
            "name": "35 – 44",
            "group": "Age",
            "ordering": 6,
            "field_type": "percentage",
            "options": {
                "capture_mechanism": "integer"
            }
        },
        {
            "id": 91,
            "value": "",
            "name": "45 – 54",
            "group": "Age",
            "ordering": 6,
            "field_type": "percentage",
            "options": {
                "capture_mechanism": "integer"
            }
        },
        {
            "id": 92,
            "value": "",
            "name": "55 – 64",
            "group": "Age",
            "ordering": 6,
            "field_type": "percentage",
            "options": {
                "capture_mechanism": "integer"
            }
        },
        {
            "id": 93,
            "value": "",
            "name": "65+",
            "group": "Age",
            "ordering": 6,
            "field_type": "percentage",
            "options": {
                "capture_mechanism": "integer"
            }
        }
    ]
  EOS
  def results
    @results = resource.all_results_for(resource.campaign.form_fields.for_event_data.includes(:kpi))

    # Save the results so they are returned with an ID
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