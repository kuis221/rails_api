class Api::V1::ActivitiesController < Api::V1::ApiController
  inherit_resources
  skip_authorization_check only: [:index]
  skip_authorize_resource only: [:index]
  belongs_to :event, :venue, optional: true

  before_action :authorize_parent, except: [:new, :show]

  respond_to :json

  def_param_group :activity do
    param :activity, Hash, required: true, action_aware: true do
      param :activity_type_id, :number, required: true, desc: 'Activity Type ID'
      param :activity_date, %r{\A\d{1,2}/\d{1,2}/\d{4}\z}, required: true, desc: 'Activity date. Should be in format MM/DD/YYYY.'
      param :results_attributes, :event_result, required: false, desc: "A list of activity results with the id and value. Eg: results_attributes: [{id: 1, value:'Some value'}, {id: 2, value: '123'}]"
      param :company_user_id, :number, desc: 'Company user ID'
      param :campaign_id, :number, desc: 'Campaign ID'
      param :event_id, :number, desc: 'Event ID'
      param :venue_id, :number, desc: 'Venue ID'
    end
  end

  api :POST, '/api/v1/events/:event_id/activities', 'Create a new activity for a event'
  api :POST, '/api/v1/events/:venue_id/activities', 'Create a new activity for a venue'
  param_group :activity
  def create
    create! do |success, failure|
      success.json { render :show }
      success.xml { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  api :PUT, '/api/v1/events/:event_id/activities/:id', 'Update a event\'s activity details'
  api :PUT, '/api/v1/events/:venue_id/activities/:id', 'Update a venue\'s activity details'
  param :event_id, :number, required: false, desc: 'Event ID'
  param :venue_id, :number, required: false, desc: 'Venue ID'
  param :id, :number, required: true, desc: 'Activity ID'
  param_group :activity
  def update
    update! do |success, failure|
      success.json { render :show }
      success.xml { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  api :GET, '/api/v1/events/:event_id/activities/:id/deactivate', 'Deactivate a event\'s activity'
  api :GET, '/api/v1/events/:venue_id/activities/:id/deactivate', 'Deactivate a venue\'s activity'
  param :event_id, :number, required: false, desc: 'Event ID'
  param :venue_id, :number, required: false, desc: 'Venue ID'
  param :id, :number, required: true, desc: 'Activity ID'

  def deactivate
    authorize! :deactivate, Activity
    resource.deactivate!
    render json: 'ok'
  end

  api :GET, '/api/v1/events/:event_id/activities', 'Get a list of activities for an Event'
  api :GET, '/api/v1/events/:venue_id/activities', 'Get a list of activities for an Venue'
  param :event_id, :number, required: false, desc: 'Event ID'
  param :venue_id, :number, required: false, desc: 'Venue ID'
  description <<-EOS
    Returns a full list of the associated activity types for a campaign
  EOS
  example <<-EOS
  {
    "data": [
      {
        "id": 5135,
        "activity_type_id": 27,
        "activity_type_name": "Jameson BA POS Drop FY15",
        "activity_date": "2015-02-06T02:00:00.000-06:00",
        "company_user_name": "Chris Jaskot"
      }
    ]
  }
  EOS
  def index
    authorize!(:show, Activity)
    collection
  end

  api :GET, '/api/v1/actvities/new', 'Return a list of fields for a new activity of a given activity type'
  param :activity_type_id, :number, required: true, desc: 'The activity type id'
  description <<-EOS
    Returns a full list of the associated activity types for a campaign
  EOS
  example <<-EOS
  {
    "id":2021,
    "activity_date":"2014-06-25T01:00:00.000-06:00",
    "campaign":{
      "id":5,
      "name":"Jameson Locals FY14"
    },
    "company_user":{
      "id":990,
      "name":"Adam Kost"
    },
    "activity_type":{
      "id":1,
      "name":"POS Drop"
    },
    "activitable":{
      "id":28205,
      "type":"Event"
    },
    "data":[
      {
        "field_id":17,
        "name":"User/Date",
        "value":null,
        "type":"FormField::UserDate",
        "settings":null,
        "ordering":0,
        "required":null,
        "kpi_id":null,
        "id":822768
      },
      {
        "field_id":3461,
        "name":"POS Drop Date",
        "value":"01/21/2015",
        "type":"FormField::Date",
        "settings":null,
        "ordering":1,
        "required":true,
        "kpi_id":null,
        "id":822764
      },
      {
        "field_id":3462,
        "name":"POS Removal Date",
        "value":"01/14/2015",
        "type":"FormField::Date",
        "settings":null,
        "ordering":2,
        "required":false,
        "kpi_id":null,
        "id":822765
      },
      {
        "field_id":1,
        "name":"Brand",
        "value":"8",
        "type":"FormField::Brand",
        "settings":null,
        "ordering":4,
        "required":true,
        "kpi_id":null,
        "segments":[
          {
            "id":8,
            "text":"Jameson Irish Whiskey"
          }
        ],
        "id":10923
      },
      {
        "field_id":2,
        "name":"Marque",
        "value":"2",
        "type":"FormField::Marque",
        "settings":{

        },
        "ordering":5,
        "required":false,
        "kpi_id":null,
        "segments":[
          {
            "id":2,
            "text":"Black Barrel"
          },
          {
            "id":13,
            "text":"Standard"
          },
          {
            "id":14,
            "text":"Gold"
          },
          {
            "id":15,
            "text":"18 Year Old"
          },
          {
            "id":16,
            "text":"Rarest Vintage Reserve"
          },
          {
            "id":17,
            "text":"12 Year Old"
          }
        ],
        "id":10924
      },
      {
        "field_id":3465,
        "name":"Seasonal Sales Program",
        "value":"1126",
        "type":"FormField::Dropdown",
        "settings":null,
        "ordering":7,
        "required":true,
        "kpi_id":null,
        "id":822766
      },
      {
        "field_id":3466,
        "name":"Movember Item(s) Dropped",
        "value":[
          703,
          705
        ],
        "type":"FormField::Checkbox",
        "settings":null,
        "ordering":8,
        "required":false,
        "kpi_id":null,
        "segments":[
          {
            "id":701,
            "text":"Posters",
            "value":false
          },
          {
            "id":702,
            "text":"Chalkboard",
            "value":false
          },
          {
            "id":703,
            "text":"Window Clings",
            "value":true
          },
          {
            "id":704,
            "text":"Coasters",
            "value":false
          },
          {
            "id":705,
            "text":"Table Tents",
            "value":true
          },
          {
            "id":706,
            "text":"Buttons",
            "value":false
          },
          {
            "id":707,
            "text":"Menu Stickers",
            "value":false
          }
        ],
        "id":822767
      },
      {
        "field_id":3,
        "name":"Miscellaneous Item(s) Dropped",
        "value":[
          2
        ],
        "type":"FormField::Checkbox",
        "settings":null,
        "ordering":9,
        "required":false,
        "kpi_id":null,
        "segments":[
          {
            "id":1,
            "text":"Chalk board",
            "value":false
          },
          {
            "id":2,
            "text":"Mirror",
            "value":true
          },
          {
            "id":3,
            "text":"Rail mat",
            "value":false
          },
          {
            "id":4,
            "text":"Wearable",
            "value":false
          },
          {
            "id":5,
            "text":"Church key",
            "value":false
          },
          {
            "id":6,
            "text":"Napkin caddie",
            "value":false
          },
          {
            "id":7,
            "text":"Poster",
            "value":false
          },
          {
            "id":21,
            "text":"Table Tent",
            "value":false
          },
          {
            "id":22,
            "text":"Glassware",
            "value":false
          },
          {
            "id":23,
            "text":"Other",
            "value":false
          }
        ],
        "id":10925
      },
      {
        "field_id":6,
        "name":"Description",
        "value":"",
        "type":"FormField::TextArea",
        "settings":null,
        "ordering":11,
        "required":false,
        "kpi_id":null,
        "id":10928
      },
      {
        "field_id":25,
        "name":"Price",
        "value":null,
        "type":"FormField::Currency",
        "settings": {
          "range_format":"digits",
          "range_max":"3",
          "range_min":"0"
        },
        "ordering":8,
        "required":true,
        "kpi_id":null,
        "id":10930
      }
    ]
  }
  EOS
  def new
    respond_to do |format|
      format.json do
        render json: {
          activity_date: resource.activity_date,
          company_user: {
            id: resource.company_user.id,
            name: resource.company_user.full_name
          },
          activity_type: {
            id: activity_type.id,
            name: activity_type.name
          },
          data: serialize_fields_for_new(activity_type.form_fields)
        }
      end
    end
  end

  api :GET, '/api/v1/actvities/:id', 'Return a list of fields with results for an existing activity'
  description <<-EOS
    Returns a full list of the associated activity types for a campaign
  EOS
  example <<-EOS
  {
    "id":2021,
    "campaign":{
      "id":5,
      "name":"Jameson Locals FY14"
    },
    "company_user":{
      "id":990,
      "name":"Adam Kost"
    },
    "activity_type":{
      "id":1,
      "name":"POS Drop"
    },
    "activitable":{
      "id":28205,
      "type":"Event"
    },
    "data":[
      {
        "field_id":17,
        "name":"User/Date",
        "value":null,
        "type":"FormField::UserDate",
        "settings":null,
        "ordering":0,
        "required":null,
        "kpi_id":null,
        "id":822768
      },
      {
        "field_id":3461,
        "name":"POS Drop Date",
        "value":"01/21/2015",
        "type":"FormField::Date",
        "settings":null,
        "ordering":1,
        "required":true,
        "kpi_id":null,
        "id":822764
      },
      {
        "field_id":3462,
        "name":"POS Removal Date",
        "value":"01/14/2015",
        "type":"FormField::Date",
        "settings":null,
        "ordering":2,
        "required":false,
        "kpi_id":null,
        "id":822765
      },
      {
        "field_id":1,
        "name":"Brand",
        "value":"8",
        "type":"FormField::Brand",
        "settings":null,
        "ordering":4,
        "required":true,
        "kpi_id":null,
        "segments":[
          {
            "id":8,
            "text":"Jameson Irish Whiskey"
          }
        ],
        "id":10923
      },
      {
        "field_id":2,
        "name":"Marque",
        "value":"2",
        "type":"FormField::Marque",
        "settings":{

        },
        "ordering":5,
        "required":false,
        "kpi_id":null,
        "segments":[
          {
            "id":2,
            "text":"Black Barrel"
          },
          {
            "id":13,
            "text":"Standard"
          },
          {
            "id":14,
            "text":"Gold"
          },
          {
            "id":15,
            "text":"18 Year Old"
          },
          {
            "id":16,
            "text":"Rarest Vintage Reserve"
          },
          {
            "id":17,
            "text":"12 Year Old"
          }
        ],
        "id":10924
      },
      {
        "field_id":3465,
        "name":"Seasonal Sales Program",
        "value":"1126",
        "type":"FormField::Dropdown",
        "settings":null,
        "ordering":7,
        "required":true,
        "kpi_id":null,
        "id":822766
      },
      {
        "field_id":3466,
        "name":"Movember Item(s) Dropped",
        "value":[
          703,
          705
        ],
        "type":"FormField::Checkbox",
        "settings":null,
        "ordering":8,
        "required":false,
        "kpi_id":null,
        "segments":[
          {
            "id":701,
            "text":"Posters",
            "value":false
          },
          {
            "id":702,
            "text":"Chalkboard",
            "value":false
          },
          {
            "id":703,
            "text":"Window Clings",
            "value":true
          },
          {
            "id":704,
            "text":"Coasters",
            "value":false
          },
          {
            "id":705,
            "text":"Table Tents",
            "value":true
          },
          {
            "id":706,
            "text":"Buttons",
            "value":false
          },
          {
            "id":707,
            "text":"Menu Stickers",
            "value":false
          }
        ],
        "id":822767
      },
      {
        "field_id":3,
        "name":"Miscellaneous Item(s) Dropped",
        "value":[
          2
        ],
        "type":"FormField::Checkbox",
        "settings":null,
        "ordering":9,
        "required":false,
        "kpi_id":null,
        "segments":[
          {
            "id":1,
            "text":"Chalk board",
            "value":false
          },
          {
            "id":2,
            "text":"Mirror",
            "value":true
          },
          {
            "id":3,
            "text":"Rail mat",
            "value":false
          },
          {
            "id":4,
            "text":"Wearable",
            "value":false
          },
          {
            "id":5,
            "text":"Church key",
            "value":false
          },
          {
            "id":6,
            "text":"Napkin caddie",
            "value":false
          },
          {
            "id":7,
            "text":"Poster",
            "value":false
          },
          {
            "id":21,
            "text":"Table Tent",
            "value":false
          },
          {
            "id":22,
            "text":"Glassware",
            "value":false
          },
          {
            "id":23,
            "text":"Other",
            "value":false
          }
        ],
        "id":10925
      },
      {
        "field_id":6,
        "name":"Description",
        "value":"",
        "type":"FormField::TextArea",
        "settings":null,
        "ordering":11,
        "required":false,
        "kpi_id":null,
        "id":10928
      },
      {
        "field_id":25,
        "name":"Price",
        "value":null,
        "type":"FormField::Currency",
        "settings": {
          "range_format":"digits",
          "range_max":"3",
          "range_min":"0"
        },
        "ordering":8,
        "required":true,
        "kpi_id":null,
        "id":10930
      },
      {
        "active":true,
        "created_at":"2015-07-02T14:50:41.091-07:00",
        "field_id":6400,
        "file_content_type":"image/png",
        "file_file_name":"blank-venues.png",
        "file_file_size":4913,
        "file_medium":"http://s3.amazonaws.com/brandscopic-dev/attached_assets/files/000/310/473/medium/blank-venues.png?1435873842",
        "file_original":"http://s3.amazonaws.com/brandscopic-dev/attached_assets/files/000/310/473/original/blank-venues.png?1435873842",
        "file_small":"http://s3.amazonaws.com/brandscopic-dev/attached_assets/files/000/310/473/small/blank-venues.png?1435873842",
        "file_thumbnail":"http://s3.amazonaws.com/brandscopic-dev/attached_assets/files/000/310/473/thumbnail/blank-venues.png?1435873842",
        "id":1268113,
        "kpi_id":null,
        "name":"Photo",
        "ordering":11,
        "required":false,
        "settings":null,
        "type":"FormField::Photo",
        "value": null
      }
    ]
  }
  EOS
  def show
    authorize! :show, resource.activitable
    results = resource.form_field_results
    results.each { |r| r.save(validate: false) if r.new_record? }
    respond_to do |format|
      format.json do
        render json: {
          id: resource.id,
          activity_date: resource.activity_date,
          campaign: {
            id: resource.campaign_id,
            name: resource.campaign_name
          },
          company_user: {
            id: resource.company_user.id,
            name: resource.company_user.full_name
          },
          activity_type: {
            id: resource.activity_type.id,
            name: resource.activity_type.name
          },
          activitable: {
            id: resource.activitable_id,
            type: resource.activitable_type
          },
          data: serialize_fields_for_edit(resource.form_field_results)
        }
      end
    end
  end

  api :GET, '/api/v1/events/:event_id/actvities/form', 'Returns a list of requred fields for uploading a file to S3'
  description <<-EOS
  This method returns all the info required to make a POST to Amazon S3 to upload a new file. The key sent to S3 should start with
  /uploads and has to be created into a new folder with a unique generated name. Ideally using a GUID. Eg:
  /uploads/9afa6775-2c8e-44f8-9cda-280e80446ced/My file.jpg

  The signature will expire 1 hour after it's generated, therefore, it's recommended to not cache these fields for long time.
  EOS
  def form
    bucket = AWS::S3.new.buckets[ENV['S3_BUCKET_NAME']]
    form = bucket.presigned_post(acl: 'public-read', success_action_status: 201)
                 .where(:key).starts_with('uploads/')
    data = { fields: form.fields, url: "https://s3.amazonaws.com/#{ENV['S3_BUCKET_NAME']}/"  }
    respond_to do |format|
      format.json { render json: data }
      format.xml { render xml: data }
    end
  end

  protected

  def activity_type
    current_company.activity_types.find(params[:activity_type_id]) if params[:activity_type_id].present?
  end

  def serialize_fields_for_new(fields)
    fields.map do |field|
      serialize_field field
    end
  end

  def serialize_fields_for_edit(results)
    results.map do |result|
      field = result.form_field
      serialize_field(field, result).merge(
        id: result.id
      )
    end
  end

  def serialize_field(field, result=nil)
    {
      field_id: field.id,
      name: field.name,
      value: nil,
      type: field.type,
      settings: field.settings,
      ordering: field.ordering,
      required: field.required,
      kpi_id: field.kpi_id
    }.merge!(custom_field_values(field, result))
  end

  def custom_field_values(field, result)
    if field.type == 'FormField::Percentage'
      { segments: (field.options_for_input.map do|s|
                    { id: s[1], text: s[0], value: result.present? && result.value.present? ? result.value[s[1].to_s].to_i : nil, goal: (field.kpi_id.present? && resource.kpi_goals.key?(field.kpi_id) ? resource.kpi_goals[field.kpi_id][s[1]] : nil) }
                  end) }
    elsif field.type == 'FormField::Checkbox'
      { value: result ? result.value || [] : nil,
        segments: field.options_for_input.map { |s| { id: s[1], text: s[0], value: result ? result.value.include?(s[1]) : false } } }
    elsif field.type == 'FormField::Radio'
      { value: result ? result.value || [] : nil,
        segments: field.options_for_input.map { |s| { id: s[1], text: s[0], value: result ? result.value.to_i.eql?(s[1]) : false } } }
    elsif field.type == 'FormField::Dropdown'
      { value: result ? result.value.to_i : nil,
        segments: field.options_for_input.map { |s| { id: s[1], text: s[0], value: result ? result.value.to_i.eql?(s[1]) : false } } }
    elsif field.type == 'FormField::Brand'
      { value: result ? result.value.to_i : nil,
        segments: field.options_for_field(result).map { |s| { id: s.id, text: s.name, value: result ? result.value.to_i.eql?(s.id) : false } } }
    elsif field.type == 'FormField::Marque'
      { value: result ? result.value.to_i : nil,
        segments: field.options_for_field(result).map { |s| { id: s[1], text: s[0], value: result ? result.value.to_i.eql?(s[1]) : false } } }
    elsif field.type == 'FormField::Summation'
      { value: result ? result.value.map { |s| s[1].to_f }.reduce(0, :+) : nil,
        segments: field.options_for_input.map { |s| { id: s[1], text: s[0], value: result ? result.value[s[1].to_s] : nil } } }
    elsif field.type == 'FormField::LikertScale'
      { statements: field.statements.order(:ordering).map { |s| { id: s.id, text: s.name, value: result ? result.value[s.id.to_s] : nil } },
        segments: field.options_for_input.map { |s| { id: s[1], text: s[0] } } }
    elsif field.type == 'FormField::Photo'
      if result.nil?
        { value: nil }
      else
        photo_values(result)
      end
    else
      value = result ? field.string_to_value(result.value) : nil
      { value: value }
    end
  end

  def photo_values(result)
    unless result.attached_asset.nil?
     {
        file_file_name: result.attached_asset.file_file_name,
        file_content_type: result.attached_asset.file_content_type,
        file_file_size: result.attached_asset.file_file_size,
        created_at: result.attached_asset.created_at,
        active: result.attached_asset.active,
        file_small: result.attached_asset.file.url(:small),
        file_thumbnail: result.attached_asset.file.url(:thumbnail),
        file_medium: result.attached_asset.file.url(:medium),
        file_original: result.attached_asset.file.url
      }
    else
      { value: nil }
    end
  end

  def activity_params
    params.require(:activity).permit([
      :activity_type_id, {
        results_attributes: [:id, :form_field_id, :value, { value: [] }, :_destroy] },
      :campaign_id, :company_user_id, :activity_date]).tap do |whielisted|
      unless whielisted.nil? || whielisted[:results_attributes].nil?
        whielisted[:results_attributes].each_with_index do |value, k|
          value[:value] = params[:activity][:results_attributes][k][:value]
        end
      end
    end
  end

  def collection
    @activities ||= end_of_association_chain.where(active: true)
  end

  def authorize_parent
    authorize!(:show, parent)
  end
end
