class Api::V1::ActivitiesController < Api::V1::ApiController
  inherit_resources

  belongs_to :event, :venue, optional: true

  skip_before_action :verify_authenticity_token,
                     if: proc { |c| c.request.format == 'application/json' }

  respond_to :json

  api :GET, '/api/v1/actvities/new', 'Return a list of fields for a new activity of a given activity type'
  param :activity_type_id, :number, required: true, desc: 'The activity type id'
  description <<-EOS
    Returns a full list of the associated activity types for a campaign
  EOS
  example <<-EOS
  [
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
    }
  ]
  EOS
  def new
    respond_to do |format|
      format.json do
        render json: serialize_fields_for_new(activity_type.form_fields)
      end
    end
  end

  api :GET, '/api/v1/actvities/:id/edit', 'Return a list of fields with results for an existing activity'
  description <<-EOS
    Returns a full list of the associated activity types for a campaign
  EOS
  example <<-EOS
  [
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
    }
  ]
  EOS
  def edit
    results = resource.form_field_results
    results.each { |r| r.save(validate: false) if r.new_record? }
    respond_to do |format|
      format.json do
        render json: serialize_fields_for_edit(resource.form_field_results)
      end
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
        id: result.id,
        value: result.value,
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
                    { id: s[1], text: s[0], value: result.value[s[1].to_s], goal: (resource.kpi_goals.key?(field.kpi_id) ? resource.kpi_goals[field.kpi_id][s[1]] : nil) }
                  end) }
    elsif field.type == 'FormField::Checkbox'
      { value: result ? result.value || [] : nil,
        segments: field.options_for_input.map { |s| { id: s[1], text: s[0], value: result ? result.value.include?(s[1]) : false } } }
    elsif field.type == 'FormField::Brand'
      { value: result ? result.value.to_i : nil,
        segments: field.options_for_field(result).map { |s| { id: s.id, text: s.name } } }
    elsif field.type == 'FormField::Marque'
      { value: result ? result.value.to_i : nil,
        segments: field.options_for_field(result).map { |s| { id: s[1], text: s[0] } } }
    elsif field.type == 'FormField::Summation'
      { value: result ? result.value.map { |s| s[1].to_f }.reduce(0, :+) : nil,
        segments: field.options_for_input.map { |s| { id: s[1], text: s[0], value: result ? result.value[s[1].to_s] : nil } } }
    elsif field.type == 'FormField::LikertScale'
      { statements: field.statements.order(:ordering).map { |s| { id: s.id, text: s.name, value: result ? result.value[s.id.to_s] : nil } },
        segments: field.options_for_input.map { |s| { id: s[1], text: s[0] } } }
    else
      {}
    end
  end

end
