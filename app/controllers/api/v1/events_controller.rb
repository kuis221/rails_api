class Api::V1::EventsController < Api::V1::FilteredController
  extend TeamMembersHelper

  skip_load_and_authorize_resource only: :update
  skip_authorization_check only: :update
  before_action :authorize_update, only: :update

  resource_description do
    short 'Events'
    formats %w(json xml)
    error 400, 'Bad Request. he server cannot or will not process the request due to something that is perceived to be a client error.'
    error 401, 'Unauthorized access'
    error 404, 'The requested resource was not found'
    error 406, 'The server cannot return data in the requested format'
    error 422, 'Unprocessable Entity: The change could not be processed because of errors on the data'
    error 500, 'Server crashed for some reason. Possible because of missing required params or wrong parameters'
    description <<-EOS

    EOS
  end

  def_param_group :event do
    param :event, Hash, required: true, action_aware: true do
      param :campaign_id, :number, required: true, desc: 'Campaign ID'
      param :start_date, %r{\A\d{1,2}/\d{1,2}/\d{4}\z}, required: true, desc: "Event's start date. Should be in format MM/DD/YYYY."
      param :end_date, %r{\A\d{1,2}/\d{1,2}/\d{4}\z}, required: true, desc: "Event's end date. Should be in format MM/DD/YYYY."
      param :start_time, String, required: true, desc: "Event's start time'. Should be in format HH:MM AM/PM"
      param :end_time, String, required: true, desc: "Event's end time. Should be in format HH:MM AM/PM"
      param :place_reference, String, required: false, desc: "Event's Place ID. This can be either an existing place id that is already registered on the application, or the combination of the place reference + place id returned by Google's places API. (See: https://developers.google.com/places/documentation/details). Those two values must be concatenated by '||' in the form of '<reference>||<place_id>'. If using the results from the API's call: Venues&nbsp;Search[link:/apidoc/1.0/venues/search.html], you should use the value for the +id+ attribute"
      param :active, String, desc: "Event's status"
      param :description, String, desc: "Event's description"
      param :results_attributes, :event_result, required: false, desc: "A list of event results with the id and value. Eg: results_attributes: [{id: 1, value:'Some value'}, {id: 2, value: '123'}]"
      param :visit_id, :number, desc: 'Visit ID'
    end
  end

  def_param_group :search_params do
    param :start_date, %r{\A\d{1,2}/\d{1,2}/\d{4}\z}, desc: 'A date to filter the event list. When provided a start_date without an +end_date+, the result will only include events that happen on this day. The date should be in the format MM/DD/YYYY.'
    param :end_date, %r{\A\d{1,2}/\d{1,2}/\d{4}\z}, desc: 'A date to filter the event list. This should be provided together with the +start_date+ param and when provided will filter the list with those events that are between that range. The date should be in the format MM/DD/YYYY.'
    param :campaign, Array, desc: 'A list of campaign ids to filter the results'
    param :place, Array, desc: 'A list of places to filter the results'
    param :venue, Array, desc: 'A list of venues to filter the results'
    param :area, Array, desc: 'A list of areas to filter the results'
    param :user, Array, desc: 'A list of users to filter the results'
    param :team, Array, desc: 'A list of teams to filter the results'
    param :brand, Array, desc: 'A list of brands to filter the results'
    param :brand_porfolio, Array, desc: 'A list of brand portfolios to filter the results'
    param :status, Array, desc: "A list of event status to filter the results. The possible options are: 'Active', 'Inactive'"
    param :event_status, Array, desc: "A list of event recap status to filter the results. The possible options are: 'Scheduled', 'Executed', 'Submitted', 'Approved', 'Rejected', 'Late', 'Due'"
    param :page, :number, desc: 'The number of the page, Default: 1'
  end

  api :GET, '/api/v1/events', 'Search for a list of events'
  api :POST, '/api/v1/events/filter', 'Search for a list of events. This is an alias method for events#index to allow sending params by POST'
  param_group :search_params
  see 'users#companies', 'User companies'

  description <<-EOS
    Returns a list of events filtered by the given params. The results are returned on groups of 30 per request. To obtain the next 30 results provide the <page> param.

    All the times and dates are returned on the user's timezone.

  EOS
  def index
    @filter_tags = FilterTags.new(params, current_company_user).tags
    collection
  end

  api :GET, '/api/v1/events/status_facets', 'Returns count of the different status given a filtering criteria'
  param_group :search_params
  description <<-EOS
    This is useful to display a counter of events for each event status

    The API returns the facets on the following format:

        facets: [                  # List of items for the facet sorted by relevance
          {
            "id": String,         # The id of the item, this should be used to filter the list by this items
            "name": String,       # The param name to be use for filtering the list (campaign, user, team, place, area, status, event_status)
            "count": Number,      # The number of results for this item
            "label": String,      # The name of the item
          },
          ....
        ]
  EOS
  def status_facets
    authorize! :index, Event

    search = resource_class.do_search(search_params, true)

    items = [:late, :due, :submitted, :rejected, :approved]

    @facets = search.facet(:status).rows.select { |f| items.include?(f.value) }.map do |f|
      items.delete(f.value)
      { id: f.value.to_s.titleize, name: :event_status, count: f.count, label: f.value.to_s.titleize }
    end

    @facets.concat(items.map { |i| { id: i.to_s.titleize, name: :event_status, count: 0, label: i.to_s.titleize } })
  end

  api :GET, '/api/v1/events/autocomplete', 'Return a list of results grouped by categories'
  param :q, String, required: true, desc: 'The search term'
  description <<-EOS
  Returns a list of results matching the searched term grouped in the following categories
  * *Campaigns*: Includes categories
  * *Brands*: Includes brands and brand portfolios
  * *Places*: Includes venues and areas
  * *Peope*: Includes users and teams
  EOS
  def autocomplete
    authorize! :index, Event
    autocomplete = Autocomplete.new('events', current_company_user, params)
    render json: autocomplete.search
  end

  api :GET, '/api/v1/events/:id', 'Return a event\'s details'
  param :id, :number, required: true, desc: 'Event ID'

  description <<-EOS
  Returns the event's details, including the actions that a user can perform on this
  event according to the user's permissions and the KPIs that are enabled for the event's campaign.

  The possible attributes returned are:
  * *id*: the event's ID
  * *start_date*: the event's start date in the format mm/dd/yyyy
  * *start_time*: the event's start time in 12 hours format
  * *end_date*: the event's end date in the format mm/dd/yyyy
  * *end_time*: the event's end time in 12 hours format
  * *description*: the event's description
  * *status*: the event's active state, can be Active or Inactive
  * *phases*: indicate the different phases and steps applicable for the event an they current status
  * *event_status*: the event's status, can be any of ['Late', 'Due', 'Submitted', 'Unsent', 'Approved', 'Rejected']
  * *have_data*: returns true if data have been entered for the event, otherwise, returns false
  * *data*: Calculated data based on event results, returned only when have_data is true
    * *spent_by_impression*: The cost for each impression. The result of total of expenses / number of impressions
    * *spent_by_interaction*: The cost for each interaction. The result of total of expenses / number of interactions
    * *spent_by_sample*: The cost for each sample. The result of total of expenses / number of samples
  * *actions*: A list of actions that the user can perform on this event with zero or more of: ["enter post event data", "upload photos", "conduct surveys", "enter expenses", "gather comments"]
  * *place*: On object with the event's venue information with the following attributes
    * *id*: the venue's id
    * *name*: the venue's name
    * *latitude*: the venue's latitude
    * *longitude*: the venue's longitude
    * *formatted_address*: the venue's formatted address
    * *country*: the venue's country
    * *state*: the venue's state code
    * *state_name*: the venue's state name
    * *city*: the venue's city
    * *route*: the venue's route
    * *street_number*: the venue's street_number
    * *zipcode*: the venue's zipcode
  * *campaign*: On object with the event's campaign information with the following attributes
    * *id*: the campaign's id
    * *name*: the campaign's name
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
  param :id, :number, required: true, desc: 'Event ID'
  param_group :event
  def update
    update! do |success, failure|
      success.json { render :show }
      success.xml  { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml  { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  api :PUT, '/api/v1/events/:id/submit', 'Submits a event for approval'
  param :id, :number, required: true, desc: 'Event ID'
  example <<-EOS
  Response when the event was successfully submitted
  PUT /api/v1/events/123/approve.json
  {
    success: true
    info: "Event successfully approved"
    data: { }
  }
  EOS

  example <<-EOS
  Response when trying to submit a event that is already submitted
  PUT /api/v1/events/123/approve.json
  {
    success: false
    info: "Event cannot transition to submitted from submitted"
    data: { }
  }
  EOS
  def submit
    authorize! :submit, resource
    status = 200
    if resource.unsent? || resource.rejected?
      begin
        resource.submit!
        result = { success: true,
                   info: 'Event successfully submitted',
                   data: {} }
      rescue AASM::InvalidTransition => e
        status = :unprocessable_entity
        result = { success: false,
                   info: resource.errors.full_messages.join("\n"),
                   data: {} }
      end
    else
      status = :unprocessable_entity
      result = { success: false,
                 info: "Event cannot transition to submitted from #{resource.aasm_state}",
                 data: {} }
    end
    respond_to do |format|
      format.json { render json: result, status: status  }
      format.xml { render xml: result, status: status }
    end
  end

  api :PUT, '/api/v1/events/:id/approve', 'Mark a event as approved'
  param :id, :number, required: true, desc: 'Event ID'
  example <<-EOS
  Response when the event was successfully approved
  PUT /api/v1/events/123/approve.json
  {
    success: true
    info: "Event successfully approved"
    data: { }
  }
  EOS

  example <<-EOS
  Response when trying to approve a event that is already approved
  PUT /api/v1/events/123/approve.json
  {
    success: false
    info: "Event cannot transition to approved from approved"
    data: { }
  }
  EOS
  def approve
    authorize! :approve, resource
    status = 200
    if resource.submitted?
      begin
        resource.approve!
        result = { success: true,
                   info: 'Event successfully approved',
                   data: {} }
      rescue AASM::InvalidTransition => e
        status = :unprocessable_entity
        result = { success: false,
                   info: resource.errors.full_messages.join("\n"),
                   data: {} }
      end
    else
      status = :unprocessable_entity
      result = { success: false,
                 info: "Event cannot transition to approved from #{resource.aasm_state}",
                 data: {} }
    end
    respond_to do |format|
      format.json { render json: result, status: status  }
      format.xml { render xml: result, status: status }
    end
  end

  api :PUT, '/api/v1/events/:id/reject', 'Mark a event as rejected'
  param :id, :number, required: true, desc: 'Event ID'
  param :reason, String, required: true, desc: 'Rejection reason (required when rejecting a event)'
  example <<-EOS
  Response when the event was successfully rejected
  PUT /api/v1/events/123/reject.json
  DATA: {
    reason: 'Please attach some photos of the event'
  }

  RESPONSE:
  {
    success: true
    info: "Event successfully rejected"
    data: { }
  }
  EOS

  example <<-EOS
  Response when trying to reject a event that is already rejected
  PUT /api/v1/events/123/reject.json
  DATA: {
    reason: 'Add the invoice for the expenses'
  }
  RESPONSE:
  {
    success: false
    info: "Event cannot transition to rejected from rejected"
    data: { }
  }
  EOS
  def reject
    authorize! :approve, resource
    status = 200
    reject_reason = params[:reason].try(:strip)
    if reject_reason.nil? || reject_reason.empty?
      status = :unprocessable_entity
      result = { success: false,
                 info: 'Must provide a reason for rejection',
                 data: {} }
    elsif resource.submitted?
      begin
        resource.reject!
        resource.update_column(:reject_reason, reject_reason)
        result = { success: true,
                   info: 'Event successfully rejected',
                   data: {} }
      rescue AASM::InvalidTransition => e
        status = :unprocessable_entity
        result = { success: false,
                   info: resource.errors.full_messages.join("\n"),
                   data: {} }
      end
    else
      status = :unprocessable_entity
      result = { success: false,
                 info: "Event cannot transition to rejected from #{resource.aasm_state}",
                 data: {} }
    end
    respond_to do |format|
      format.json { render json: result, status: status  }
      format.xml { render xml: result, status: status }
    end
  end

  api :GET, '/api/v1/events/:id/results', 'Get the list of results for the events'
  param :id, :number, required: true, desc: 'Event ID'
  description <<-EOS
  Returns a list of form fields based on the event's campaign. The fields are grouped by category/module.
  Each category have the followign attributes:
  * *module*: the module's id
  * *label*: the module's label
  * *fields*: a list of fields for the module, the definition of this list is described below.

  Each campaign can have a different set of fields that have to be capture for its events. a field returned
  by the API consists on the ['submit', 'approve', 'submit'].include?(params[:status])

  * *id:* the id of the field that have to be used later save the results. Please see the documentation
    for saving a devent. This is not included for "percentage" fields as such fields have to be sent to
    the API as separate fields. See the examples for more detail.

  * *value:* the event's current value for that field. This should be used to pre-populate the field or
  * *value:* the event's current value for that field. This should be used to pre-populate the field or
    to select the correspondent options for the case of radio buttons/checboxes/dropdown.

    For "count" fields, this is filled with the id of the currently selected +segment+ (see the "segments" section below)

  * *name:* the label of the field

  * *ordering:* how this field is ordered in the event's campaign.

  * *field_type:* what kind of field is this, the possible options are: "number", "count", "percentage", "text", "textarea"

  * *description:* the field's description

  * *goal:* the goal for this field on the event's campaign (only present if +fied_type+ is NOT "count" or "percentage", for such fields the goal is specified on the segment level)

  * *segments:* when the +fied_type+ is either "count" or "percentage", this will enumerate the possible
    options for the "count" fields or the different subfields for the "percentage" fields.

    This will contain a list with the following attributes:

    * *id:* this is the ID of the option (for count fields) or sub-field (for percentage fields)

    * *text:* the label/text for the option/sub-field

    * *value:* (for percentage fields only) the current value for this segment, the sum for all fields' segments should be 100

    * *goal:* the goal for this segment on the event's campaign

  * *options:* specific options for this field, depending of the field_type these can be:

    * *capture_mechanism:* especifies how should the data should be captured for this field, the possible options are:

      * If the +field_type+ is "number" then: "integer", "decimal" or "currency"
      * If the +field_type+ is "count" then: "radio", "dropdown" or "checkbox"
      * If the +field_type+ is "currency" then: "integer" or "decimal"
      * If the +field_type+ is "text" then: _null_
      * If the +field_type+ is "textarea" then: _null_

    * *predefined_value:* if the field have this attribute and the +value+ is empty, this should be used as the default value for the event

    * *required:* indicates whether this field is required or not

  * *range:* contains the range constraints for the field if any. This will be provided with the following info:

    * *format:* either digits or value for numeric fields or words, characters for text fields
    * *min:* the mininum number of chars/words/digits/value accepted by this field
    * *max:* the max number of chars/words/digits/value accepted by this field

    A field can include both min or max, or only a min or a max and it validates the info based in the following rules:

    * min and max: the value must be between `min` and `max`
    * min only: the value must be greater than `min`
    * max only: the value must be smaller than `max`
  EOS
  def results
    authorize! :view_or_edit_data, resource
    fields = resource.campaign.form_fields.includes(:kpi)

    # Save the results so they are returned with an ID
    resource.results_for(fields).each { |r| r.save(validate: false) if r.new_record? }

    results = fields.map do |field|
      r = resource.results_for([field]).first
      result = { name: field.name, ordering: field.ordering, type: field.type, required: field.required?, description: nil }
      result[:module] = field.kpi.module unless field.kpi.nil?
      result[:goal] = resource.kpi_goals[field.kpi_id] unless field.is_optionable?
      result[:module] ||= 'custom'
      result[:id] = r.id
      if field.type == 'FormField::Percentage'
        result.merge!(segments: field.options_for_input.map do|s|
                                  { id: s[1], text: s[0], value: r.value[s[1].to_s], goal: (resource.kpi_goals.key?(field.kpi_id) ? resource.kpi_goals[field.kpi_id][s[1]] : nil) }
                                end)
      elsif field.type == 'FormField::Checkbox'
        result.merge!(value: r.value || [],
                      segments: field.options_for_input.map { |s| { id: s[1], text: s[0], value: r.value.include?(s[1]) } })
      elsif field.type == 'FormField::Brand' || field.type == 'FormField::Marque'
        result.merge!(value: r.value.to_i,
                      segments: field.options_for_field(r).map do|s|
                                  { id: s[:id], text: s[:name] }
                                end)
      elsif field.type == 'FormField::Summation'
        result.merge!(value: r.value.map { |s| s[1].to_f }.reduce(0, :+),
                      segments: field.options_for_input.map { |s| { id: s[1], text: s[0], value: r.value[s[1].to_s] } })
      elsif field.type == 'FormField::LikertScale'
        result.merge!(statements: field.statements.order(:ordering).map { |s| { id: s.id, text: s.name, value: r.value[s.id.to_s] } },
                      segments: field.options_for_input.map { |s| { id: s[1], text: s[0] } })
      else
        if field.is_optionable?
          result.merge!(segments: field.options_for_input.map { |s| { id: s[1], text: s[0], goal: (field.kpi_id.present? && resource.kpi_goals.key?(field.kpi_id) ? resource.kpi_goals[field.kpi_id][s[1]] : nil) } })
        end
        v = field.value_is_numeric?(r.value) ? r.value.to_f : r.value
        if field.settings && field.settings.key?('range_format') && (!field.settings['range_min'].blank? || !field.settings['range_max'].blank?)
          result[:range] = { format: field.settings['range_format'], min: field.settings['range_min'], max: field.settings['range_max'] }
        end
        result.merge!(value: v)
      end

      result.merge!(description: field.kpi.description) if field.kpi.present?
      result.merge!(description: field.settings['description']) if field.settings && field.settings.key?('description')

      result
    end

    grouped = []
    group = nil
    results.each do |result|
      if group.nil? || result[:module] != group[:module]
        group = { module: result[:module], fields: [], label:  I18n.translate("form_builder.modules.#{result[:module]}") }
        if result[:module] != 'custom' && exising = grouped.find { |g| g[:module] == result[:module] } # Try to find the module in the current list
          group = exising
        else
          grouped.push group
        end
      end
      group[:fields].push result
    end

    respond_to do |format|
      format.json do
        render status: 200,
               json: grouped
      end
      format.xml do
        render status: 200,
               xml: grouped.to_xml(root: 'results')
      end
    end
  end

  api :GET, '/api/v1/events/:id/members', 'Get a list of users and teams associated to the event'
  param :id, :number, required: true, desc: 'Event ID'
  param :type, %w(user team), required: false, desc: 'Filter the results by type'
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
  def members
    authorize! :view_members, resource
    @users = @teams = []
    @users = resource.users.with_user_and_role.order('users.first_name, users.last_name') unless params[:type] == 'team'
    @teams = resource.teams.order(:name) unless params[:type] == 'user'
    @members = (@users + @teams).sort { |a, b| a.name.downcase <=> b.name.downcase }
  end

  api :GET, '/api/v1/events/:id/assignable_members', "Get a list of users+teams that can be associated to the event's team"
  param :id, :number, required: true, desc: 'Event ID'
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
  def assignable_members
    authorize! :add_members, resource
    respond_to do |format|
      format.json do
        render status: 200,
               json: assignable_staff_members
      end
      format.xml do
        render status: 200,
               xml: assignable_staff_members
      end
    end
  end

  api :POST, '/api/v1/events/:id/members', 'Associate an user or team to the event\'s team'
  param :memberable_id, :number, required: true, desc: 'The ID of team/user to be added as a member'
  param :memberable_type, %w(user team), required: true, desc: 'The type of element to be added as a member'
  see 'events#assignable_members'
  def add_member
    authorize! :add_members, resource
    memberable = build_memberable_from_request
    if memberable.save
      resource.solr_index
      result = { success: true,
                 info: 'Member successfully added to event',
                 data: {} }
      respond_to do |format|
        format.json do
          render status: 200,
                 json: result
        end
        format.xml do
          render status: 200,
                 xml: result.to_xml(root: 'result')
        end
      end
    else
      respond_to do |format|
        format.json { render json: memberable.errors, status: :unprocessable_entity }
        format.xml { render xml: memberable.errors, status: :unprocessable_entity }
      end
    end
  end

  api :DELETE, '/api/v1/events/:id/members', 'Delete an user or team from the event\'s team'
  param :memberable_id, :number, required: true, desc: 'The ID of team/user to be deleted as a member'
  param :memberable_type, %w(user team), required: true, desc: 'The type of element to be deleted as a member'
  def delete_member
    authorize! :delete_member, resource
    memberable = find_memberable_from_request
    if memberable.present?
      if memberable.destroy
        resource.solr_index
        render status: 200,
               json: { success: true,
                       info: 'Member successfully deleted from event',
                       data: {}
                        }
      else
        render json: memberable.errors, status: :unprocessable_entity
      end
    else
      record_not_found
    end
  end

  api :GET, '/api/v1/events/:id/contacts', 'Get a list of users+contacts associated to the event'
  param :id, :number, required: true, desc: 'Event ID'
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
    GET: /api/v1/events/8383/contacts.json
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
    GET: /api/v1/events/8383/contacts.json
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
    authorize! :view_contacts, resource
    @contacts = resource.contacts
  end

  api :GET, '/api/v1/events/:id/assignable_contacts', 'Get a list of contacts+users that can be associated to the event as a contact'
  param :id, :number, required: true, desc: 'Event ID'
  param :term, String, required: false, desc: 'A search term to filter the list of contacts/events'
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
  def assignable_contacts
    authorize! :add, ContactEvent
    @contacts =  ContactEvent.contactables_for_event(resource, params[:term])
  end

  api :POST, '/api/v1/events/:id/contacts', 'Associate a contact to the event'
  param :contactable_id, :number, required: true, desc: 'The ID of contact/user to be added as a contact'
  param :contactable_type, %w(user contact), required: true, desc: 'The type of element to be added as a contact'
  see 'events#assignable_contacts'
  def add_contact
    authorize! :create_contacts, resource
    contact = resource.contact_events.build(contactable: load_contactable_from_request)
    if contact.save
      result = { success: true,
                 info: 'Contact successfully added to event',
                 data: {} }
      respond_to do |format|
        format.json do
          render status: 200,
                 json: result
        end
        format.xml do
          render status: 200,
                 xml: result.to_xml(root: 'result')
        end
      end
    else
      respond_to do |format|
        format.json { render json: contact.errors, status: :unprocessable_entity }
        format.xml { render xml: contact.errors, status: :unprocessable_entity }
      end
    end
  end

  api :DELETE, '/api/v1/events/:id/contacts', 'Delete a contact from the event'
  param :contactable_id, :number, required: true, desc: 'The ID of contact/user to be deleted as a contact'
  param :contactable_type, %w(user contact), required: true, desc: 'The type of element to be deleted as a contact'
  def delete_contact
    authorize! :delete_contact, resource
    contact = find_contactable_from_request
    if contact.present?
      if contact.destroy
        resource.solr_index
        render status: 200,
               json: { success: true,
                       info: 'Contact successfully deleted from event',
                       data: {}
                        }
      else
        render json: contact.errors, status: :unprocessable_entity
      end
    else
      record_not_found
    end
  end

  api :GET, '/api/v1/events/requiring_attention', 'Return a list of events requiring the users attention'
  def requiring_attention
    authorize! :index, Event
    @events = events_requiring_attention
  end

  protected

  def permitted_params
    parameters = {}
    allowed = []
    allowed += [:end_date, :end_time, :start_date, :start_time, :campaign_id, :place_id,
                :place_reference, :description, :visit_id] if can?(:update, Event) || can?(:create, Event)
    allowed += [{ results_attributes: [:value, :id, { value: [] }] }] if can?(:edit_data, Event)
    allowed += [:active] if can?(:deactivate, Event)
    parameters = params.require(:event).permit(*allowed)
    parameters.tap do |whielisted|
      unless whielisted.nil? || whielisted[:results_attributes].nil?
        whielisted[:results_attributes].each_with_index do |value, i|
          value[:value] = params[:event][:results_attributes][i][:value]
        end
      end
    end
  end

  def permitted_search_params
    params.permit(:page, campaign: [], place: [], area: [], venue: [], start_date: [], end_date: [],
                             user: [], team: [], brand: [], brand_porfolio: [], status: [], event_status: []).tap do |p|
      p[:sorting] ||= 'start_at'
      p[:sorting_dir] ||= 'asc'
    end
  end

  def load_contactable_from_request
    if params[:contactable_type] == 'user'
      current_company.company_users.find(params[:contactable_id])
    else
      current_company.contacts.find(params[:contactable_id])
    end
  end

  def find_contactable_from_request
    contactable_type = params[:contactable_type] == 'user' ? 'CompanyUser' : 'Contact'
    resource.contact_events.where(contactable_id: params[:contactable_id], contactable_type: contactable_type).first
  end

  def build_memberable_from_request
    if params[:memberable_type] == 'team'
      resource.teamings.build(team: current_company.teams.find(params[:memberable_id]))
    else
      resource.memberships.build(company_user: current_company.company_users.find(params[:memberable_id]))
    end
  end

  def find_memberable_from_request
    if params[:memberable_type] == 'team'
      resource.teamings.where(team_id: params[:memberable_id], teamable_id: params[:id]).first
    else
      resource.memberships.where(company_user_id: params[:memberable_id], memberable_id: params[:id]).first
    end
  end

  def authorize_update
    return unless cannot?(:update, resource) && cannot?(:edit_data, resource)

    fail CanCan::AccessDenied, unauthorized_message(:update, resource)
  end

  def events_requiring_attention
    Event.do_search(
      company_id: current_company.id,
      current_company_user: current_company_user,
      start_date: '01/01/1900',
      end_date: Time.zone.now.to_s(:slashes),
      event_status: %w(Late Due Rejected Unsent)).results
  end
end
