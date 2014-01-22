class Api::V1::EventsController < Api::V1::FilteredController
  resource_description do
    short 'Events'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Unauthorized access"
    error 500, "Server crashed for some reason"
    param :auth_token, String, required: true, desc: "User's authorization token returned by login method"
    param :company_id, :number, required: true, desc: "One of the allowed company ids returned by the \"User companies\" API method"
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
      param :place_reference, String, required: false, desc: "Event's Place ID. This can be either an existing place id that is already registered on the application, or the combination of the place reference + place id returned by Google's places API. (See: https://developers.google.com/places/documentation/details). Those two values must be concatenated by '||' in the form of '<reference>||<place_id>'. If using the results from the API's call: Venues&nbsp;Search[link:/apidoc/1.0/venues/search.html], you should use the value for the +id+ attribute"
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
  param :event_status, ['Scheduled', 'Executed', 'Submitted', 'Approved', 'Rejected', 'Late', 'Due'], :desc => "A list of event recap status to filter the results"
  param :page, :number, :desc => "The number of the page, Default: 1"
  see "users#companies", "User companies"

  description <<-EOS
    Returns a list of events filtered by the given params. The results are returned on groups of 30 per request. To obtain the next 30 results provide the <page> param.

    All the times and dates are returned on the user's timezone.

    *Facets*

    Faceting is a feature of Solr that determines the number of documents that match a given search and an additional criteria

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

  api :POST, '/api/v1/events', 'Create a new event'
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
  Returns a list of form fields based on the event's campaign. Each campaign can have a
  different set of fields that have to be capture for its events. a field returned by the
  API consists on the following attributes:

  * *id:* the id of the field that have to be used later save the results. Please see the documentation
    for saving a devent. This is not included for "percentage" fields as such fields have to be sent to
    the API as separate fields. See the examples for more detail.

  * *value:* the event's current value for that field. This should be used to pre-populate the field or
    to select the correspondent options for the case of radio buttons/checboxes/dropdown.

    For "count" fields, this is filled with the id of the currently selected +segment+ (see the "segments" section below)

  * *name:* the label of the field

  * *ordering:* how this field is ordered in the event's campaign.

  * *field_type:* what kind of field is this, the possible options are: "number", "count", "percentage", "text", "textarea"

  * *description:* the field's description

  * *segments:* when the +fied_type+ is either "count" or "percentage", this will enumerate the possible
    options for the "count" fields or the different subfields for the "percentage" fields.

    This will contain a list with the following attributes:

    * *id:* this is the ID of the option (for count fields) or sub-field (for percentage fields)

    * *text:* the label/text for the option/sub-field

    * *value:* (for percentage fields only) the current value for this segment, the sum for all fields' segments should be 100

  * *options:* specific options for this field, depending of the field_type these can be:

    * *capture_mechanism:* especifies how should the data should be captured for this field, the possible options are:

      * If the +field_type+ is "number" then: "integer", "decimal" or "currency"
      * If the +field_type+ is "count" then: "radio", "dropdown" or "checkbox"
      * If the +field_type+ is "currency" then: "integer" or "decimal"
      * If the +field_type+ is "text" then: _null_
      * If the +field_type+ is "textarea" then: _null_

    * *predefined_value:* if the field have this attribute and the +value+ is empty, this should be used as the default value for the event

    * *required:* indicates whether this field is required or not

  EOS
  example  <<-EOS
    A response with all the different kind of fields
    [
        {
            "id": 80,
            "value": "5",
            "name": "Impressions",
            "ordering": 1,
            "field_type": "number",
            "options": {
                "capture_mechanism": "integer",
                "predefined_value": "",
                "required": "true"
            }
        },
        {
            "id":81,
            "value":null,
            "name":"Banner Displayed",
            "segments":[
                {
                  "id":93,
                  "text":"Yes"
                },
                {
                  "id":94,
                  "text":"No"
                }
            ],
            "ordering":2,
            "field_type":"count",
            "options":{
               "capture_mechanism":"radio"
            }
        },
        {
            "value": "30",
            "name": "Gender",
            "ordering": 3,
            "field_type": "percentage",
            "segments":[
                {
                  "id":84,
                  "text":"Female",
                  "value": 55
                },
                {
                  "id":85,
                  "text":"Male",
                  "value": 45
                }
            ],
            "options": {
                "capture_mechanism": "integer"
            }
        },
        {
            "id": 80,
            "value": "5",
            "name": "Manager Name",
            "ordering": 4,
            "field_type": "text",
            "options": {
                "capture_mechanism": null
            }
        },
        {
            "id": 80,
            "value": "5",
            "name": "Manager Comments",
            "ordering": 4,
            "field_type": "textarea",
            "options": {
                "capture_mechanism": null
            }
        }
    ]
  EOS
  def results
    @fields = resource.campaign.form_fields.for_event_data.includes(:kpi)

    # Save the results so they are returned with an ID
    resource.all_results_for(@fields).each{|r| r.save(validate: false) if r.new_record? }

    results = @fields.map do |field|
      result = {name: field.name, ordering: field.ordering, field_type: field.field_type, options: field.options, description: nil}
      if field.field_type == 'percentage'
        result.merge!({segments: resource.segments_results_for(field).map{|r| {id: r.id, text: r.kpis_segment.text, value: r.value}}})
      else
        if field.field_type == 'count'
          result.merge!({segments: field.kpi.kpis_segments.map{|s| {id: s.id, text: s.text}}})
        end
        r = resource.results_for([field]).first
        result.merge!({id: r.id, value: r.value})
      end

      result.merge!(description: field.kpi.description) if field.kpi.present?

      result
    end

    respond_to do |format|
        format.json {
          render :status => 200,
                 :json => results
        }
        format.xml {
          render :status => 200,
                 :xml => results.to_xml(root: 'results')
        }
    end
  end

  api :GET, '/api/v1/events/:id/members', "Get a list of users and teams associated to the event"
  param :id, :number, required: true, desc: "Event ID"
  param :type, ['user', 'team'], required: false, desc: "Filter the results by type"
  description <<-EOS
    Returns a mixed list of teams and users that are part of the event's team. The items are sorted by name.

    Each results have the following attributes:
    * For users:
      * *id*: the user id
      * *first_name*: the user's first name
      * *last_name*: the user's last name
      * *full_name*: the user's full name
      * *email*: the user's email address
      * *street_address*: the user's street name and number
      * *city*: the user's city name
      * *state*: the user's state code
      * *country*: the user's country
      * *zip_code*: the user's ZIP code
      * *role_name*: the user's role name
      * *type*: the type of the current item (user)

    * For teams:
      * *id*: the user id
      * *name*: the teams's name
      * *description*: the teams's description
      * *type*: the type of the current item (team)

  EOS

  example <<-EOS
    An example with a event with both, users and teams
    GET: /api/v1/events/8383/members.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
        {
            "id": 22,
            "name": "Northerners", "description": "he people from the north",
            "type": "team"
        },
        {
            "id": 268,
            "first_name": "Trinity",
            "last_name": "Ruiz",
            "full_name": "Trinity Ruiz",
            "role_name": "MBN Supervisor",
            "email": "trinity.ruiz@gmail.com",
            "phone_number": "+1 233 245 4332",
            "street_address": "1st Young st.,",
            "city": "Toronto",
            "state": "ON",
            "country": "Canada",
            "zip_code": "Canada",
            "type": "user"
        },
        {
            "id":  1,
            "name": "Southerners",
            "description": "The people from the south",
            "type": "team"
        }
    ]
  EOS

  example <<-EOS
    An example with a event with only users and no teams
    GET: /api/v1/events/8383/members.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
        {
            "id": 268,
            "first_name": "Trinity",
            "last_name": "Ruiz",
            "full_name": "Trinity Ruiz",
            "role_name": "MBN Supervisor",
            "phone_number": "+1 233 245 4332",
            "street_address": "1st Young st.,",
            "city": "Toronto",
            "state": "ON",
            "country": "Canada",
            "zip_code": "12345",
            "type": "user"
        }
    ]
  EOS


  example <<-EOS
    An example requesting only the teams and not the users
    GET: /api/v1/events/8383/members.json?type=team&auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
        {
            "id": 22,
            "name": "Northerners", "description": "he people from the north",
            "type": "team"
        },
        {
            "id":  1,
            "name": "Southerners",
            "description": "The people from the south",
            "type": "team"
        }
    ]
  EOS
  def members
    @users = @teams = []
    @users = resource.users.with_user_and_role.order('users.first_name, users.last_name') unless params[:type] == 'team'
    @teams = resource.teams.order(:name) unless params[:type] == 'user'
    @members = (@users + @teams).sort{|a, b| a.name.downcase <=> b.name.downcase }
  end

  api :GET, '/api/v1/events/:id/assignable_members', "Get a list of users+teams that can be associated to the event's team"
  param :id, :number, required: true, desc: "Event ID"
  description <<-EOS
    Returns a list of contacts that can be associated to the event, including users but excluding those that are already associted.

    The results are sorted by +full_name+.

    Each item have the following attributes:
    * *id*: the user id
    * *name*: the user or team's name
    * *description*: the user's role name or the team's descrition
    * *type*: indicates if the current item is a user or a team
  EOS
  see 'events#add_member'

  example <<-EOS
    An example with a user and a contact in the response
    GET: /api/v1/events/8383/assignable_members.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
      {
          "id": 268,
          "name": "Trinity Ruiz",
          "description": "Bartender",
          "type": "user"
      },{
          "id": 268,
          "name": "San Francisco MBN Team",
          "description": "Field Ambassador",
          "type": "team"
      }
    ]
  EOS
  def assignable_members
    @members =  (
      current_company.company_users.with_user_and_role.where('company_users.id not in (?)', resource.user_ids+[0]).all +
      current_company.teams.where('teams.id not in (?)', resource.team_ids+[0])
    ).sort{|a, b| a.name <=> b.name}
  end

  api :POST, '/api/v1/events/:id/members', 'Assocciate a user or team to the event\'s team'
  param :memberable_id, :number, required: true, desc: 'The ID of team/user to be added as a member'
  param :memberable_type, ['user','team'], required: true, desc: 'The type of element to be added as a member'
  see 'events#assignable_members'

  example <<-EOS
    Adding a user to the event members
    POST: /api/v1/events/8383/members.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    DATA:
    {
      'memberable_id': 1,
      'memberable_type': 'user'
    }

    RESPONSE:
    {
      'success': true,
      'info': "Contact successfully added to event",
      'data': {}
    }
  EOS

  example <<-EOS
    Adding a contact to the event members
    POST: /api/v1/events/8383/members.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    DATA:
    {
      'memberable_id': 1,
      'memberable_type': 'contact'
    }

    RESPONSE:
    {
      'success': true,
      'info': "Contact successfully added to event",
      'data': {}
    }
  EOS
  def add_member
    memberable = build_memberable_from_request
    if memberable.save
      result = { :success => true,
                 :info => "Member successfully added to event",
                 :data => {} }
      respond_to do |format|
        format.json do
          render :status => 200,
                 :json => result
        end
        format.xml do
          render :status => 200,
                 :xml => result.to_xml(root: 'result')
        end
      end
    else
      respond_to do |format|
        format.json { render json: memberable.errors, status: :unprocessable_entity }
        format.xml { render xml: memberable.errors, status: :unprocessable_entity }
      end
    end
  end

  api :GET, '/api/v1/events/:id/contacts', "Get a list of users+contacts associated to the event"
  param :id, :number, required: true, desc: "Event ID"
  description <<-EOS
    Returns a mixed list of users+contacts that are associated to the event. The results are sorted by the contact's full name.

    Each contact have the following attributes:
    * For contacts:
      * *id*: the user id
      * *first_name*: the user's first name
      * *last_name*: the user's last name
      * *full_name*: the user's full name
      * *title*: the user's title
      * *email*: the user's email address
      * *phone_number*: the user's phone number
      * *street_address*: the user's street name and number
      * *city*: the user's city name
      * *state*: the user's state code
      * *country*: the user's country
      * *zip_code*: the user's ZIP code
      * *type*: the type of the current item (contact)

    * For users:
      * *id*: the user id
      * *first_name*: the user's first name
      * *last_name*: the user's last name
      * *full_name*: the user's full name
      * *role_name*: the user's role name
      * *email*: the user's email address
      * *street_address*: the user's street name and number
      * *city*: the user's city name
      * *state*: the user's state code
      * *country*: the user's country
      * *zip_code*: the user's ZIP code
      * *type*: the type of the current item (user)
  EOS

  example <<-EOS
    An example with a event with one contact
    GET: /api/v1/events/8383/contacts.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
      {
          "id": 268,
          "first_name": "Trinity",
          "last_name": "Ruiz",
          "full_name": "Trinity Ruiz",
          "title": "Bartender",
          "email": "trinity.ruiz@gmail.com",
          "phone_number": "+1 233 245 4332",
          "street_address": "1st Young st.,",
          "city": "Toronto",
          "state": "ON",
          "country": "Canada",
          "zip_code": "12345"
      }
    ]
  EOS
  example <<-EOS
    An example with a event with one contact and one user
    GET: /api/v1/events/8383/contacts.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
      {
          "id": 268,
          "first_name": "Trinity",
          "last_name": "Ruiz",
          "full_name": "Trinity Ruiz",
          "title": "Bartender",
          "email": "trinity.ruiz@gmail.com",
          "phone_number": "+1 233 245 4332",
          "street_address": "1st Young st.,",
          "city": "Toronto",
          "state": "ON",
          "country": "Canada",
          "zip_code": "12345",
          "type": "contact"
      },
      {
          "id": 223,
          "first_name": "Pablo",
          "last_name": "Brenes",
          "full_name": "Pablo Brenes",
          "role_name": "MBN Supervisor",
          "phone_number": "+1 243 222 4332",
          "street_address": "1st Felicity st.,",
          "city": "Los Angeles",
          "state": "CA",
          "country": "United States",
          "zip_code": "23343",
          "type": "user"
        }
    ]
  EOS
  def contacts
    @contacts = resource.contacts
  end

  api :GET, '/api/v1/events/:id/assignable_contacts', "Get a list of contacts+users that can be associated to the event as a contact"
  param :id, :number, required: true, desc: "Event ID"
  param :term, String, required: false, desc: "A search term to filter the list of contacts/events"
  description <<-EOS
    Returns a list of contacts that can be associated to the event, including users but excluding those that are already associted.

    The results are sorted by +full_name+.

    Each item have the following attributes:
    * *id*: the user id
    * *full_name*: the user's full name
    * *title*: the user's title
    * *type*: indicates if the current item is a user or contact
  EOS
  see 'events#add_contact'

  example <<-EOS
    An example with a user and a contact in the response
    GET: /api/v1/events/8383/assignable_contacts.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    [
      {
          "id": 268,
          "full_name": "Trinity Ruiz",
          "title": "Bartender",
          "type": "contact"
      },{
          "id": 268,
          "full_name": "Jonh Connor",
          "title": "Human Soldier",
          "type": "user"
      }
    ]
  EOS

  example <<-EOS
    An example with a term search
    GET: /api/v1/events/8383/assignable_contacts.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1&term=ruiz
    [
      {
          "id": 268,
          "full_name": "Trinity Ruiz",
          "title": "Bartender",
          "type": "contact"
      },{
          "id": 268,
          "full_name": "Bryan Ruiz",
          "title": "Field Ambassador",
          "type": "user"
      }
    ]
  EOS
  def assignable_contacts
    @contacts =  ContactEvent.contactables_for_event(resource, params[:term])
  end

  api :POST, '/api/v1/events/:id/contacts', 'Assocciate a contact to the event'
  param :contactable_id, :number, required: true, desc: 'The ID of contact/user to be added as a contact'
  param :contactable_type, ['user','contact'], required: true, desc: 'The type of element to be added as a contact'
  see 'events#assignable_contacts'

  example <<-EOS
    Adding a user to the event contacts
    POST: /api/v1/events/8383/contacts.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    DATA:
    {
      'contactable_id': 1,
      'contactable_type': 'user'
    }

    RESPONSE:
    {
      'success': true,
      'info': "Contact successfully added to event",
      'data': {}
    }
  EOS

  example <<-EOS
    Adding a contact to the event contacts
    POST: /api/v1/events/8383/contacts.json?auth_token=swyonWjtcZsbt7N8LArj&company_id=1
    DATA:
    {
      'contactable_id': 1,
      'contactable_type': 'contact'
    }

    RESPONSE:
    {
      'success': true,
      'info': "Contact successfully added to event",
      'data': {}
    }
  EOS
  def add_contact
    contact = resource.contact_events.build({contactable: load_contactable_from_request}, without_protection: true)
    if contact.save
      result = { :success => true,
                 :info => "Contact successfully added to event",
                 :data => {} }
      respond_to do |format|
        format.json do
          render :status => 200,
                 :json => result
        end
        format.xml do
          render :status => 200,
                 :xml => result.to_xml(root: 'result')
        end
      end
    else
      respond_to do |format|
        format.json { render json: contact.errors, status: :unprocessable_entity }
        format.xml { render xml: contact.errors, status: :unprocessable_entity }
      end
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
      params.permit({campaign: []}, {status: []}, {event_status: []})
    end

    def load_contactable_from_request
      if params[:contactable_type] == 'user'
        current_company.company_users.find(params[:contactable_id])
      else
        current_company.contacts.find(params[:contactable_id])
      end
    end

    def build_memberable_from_request
      if params[:memberable_type] == 'team'
        resource.teamings.build({team: current_company.teams.find(params[:memberable_id])}, without_protection: true)
      else
        resource.memberships.build({company_user: current_company.company_users.find(params[:memberable_id])}, without_protection: true)
      end
    end

end