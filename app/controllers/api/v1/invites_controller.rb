class Api::V1::InvitesController < Api::V1::ApiController
  inherit_resources

  belongs_to :event, :venue, optional: true

  skip_authorize_resource only: [:show, :update]
  skip_authorization_check only: [:show, :update]
  before_action :authorize_update, only: :update

  resource_description do
    short 'Invites'
    formats %w(json xml)
    error 400, 'Bad Request. he server cannot or will not process the request due to something that is perceived to be a client error.'
    error 404, 'Missing'
    error 401, 'Unauthorized access'
    error 500, 'Server crashed for some reason'
    description <<-EOS

    EOS
  end

  def_param_group :invite do
    param :invite, Hash, required: true, action_aware: true do
      param :active, %w(true false), desc: "Invitation's status"
    end
  end

  api :GET, '/api/v1/events/:event_id/invites', 'Get a list of invites for an Event'
  param :event_id, :number, required: false, desc: 'Event ID'
  param :venue_id, :number, required: false, desc: 'Venue ID'
  example <<-EOS
  GET /api/v1/events/1223/invites
       [
          {
            "id":133,
            "invitees":5,
            "rsvps_count":7,
            "attendees":10,
            "active":true,
            "event":{
              "id":38292,
              "start_date":"06/28/2014",
              "end_date":"06/28/2014",
              "campaign":{
                "id":115,
                "name":"Absolut BA FY15"
              }
            },
            "venue":{
              "id":337,
              "name":"High Dive",
              "top_venue":false,
              "jameson_locals":false
            }
          },
          {
            "id":134,
            "invitees":5,
            "rsvps_count":7,
            "attendees":10,
            "active":true,
            "event":{
              "id":38292,
              "start_date":"06/28/2014",
              "end_date":"06/28/2014",
              "campaign":{
                "id":115,
                "name":"Absolut BA FY15"
              }
            },
            "venue":{
              "id":337,
              "name":"High Dive",
              "top_venue":false,
              "jameson_locals":false
            }
          }
          ...
      ]
  EOS
  def index
    authorize!(:index_invites, parent)
    @invites = parent.invites.where(active: true)
  end

  def show
    authorize!(:index_invites, parent)
    if resource.present?
      render
    end
  end

  api :POST, '/api/v1/events', 'Create a new invite'
  param_group :invite
  example <<-EOS
  POST /api/v1/events/192/attendance.json
  DATA:
  {
    invite: {
      place_reference: 19,
      venue_id: 19,
      invitees: 10,
      attendees: 23,
      rsvps_count: 12
    }
  }

  RESPONSE:
  {
    "id":7,
    "invitees":10,
    "rsvps_count":12,
    "attendees":23,
    "active":true,
    "event":{
      "id":38292,
      "start_date":"06/28/2014",
      "end_date":"06/28/2014",
      "campaign":{
        "id":115,
        "name":"Absolut BA FY15"
      }
    },
    "venue":{
      "id":4,
      "name":"Big's 108",
      "top_venue":false,
      "jameson_locals":false
    }
  }
  EOS
  def create
    create! do |success, failure|
      success.json { render :show }
      success.xml { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  api :PUT, '/api/v1/events/:id', 'Update a event\'s details'
  param :event_id, :number, required: false, desc: 'Event ID'
  param :venue_id, :number, required: false, desc: 'Venue ID'
  param :id, :number, required: true, desc: 'Invite ID'
  param_group :invite
  def update
    update! do |success, failure|
      success.json { render :show }
      success.xml  { render :show }
      failure.json { render json: resource.errors, status: :unprocessable_entity }
      failure.xml  { render xml: resource.errors, status: :unprocessable_entity }
    end
  end

  protected

  def invite_params
    parameters = {}
    allowed = []
    allowed += [:event_id, :venue_id, :attendees, :invitees, :rsvps_count, :place_reference] if can?(:edit_invite, Event) || can?(:create_invite, Event) || can?(:edit_invite, Venue) || can?(:create_invite, Venue)
    allowed += [:active] if can?(:deactivate_invite, Event) || can?(:deactivate_invite, Venue)
    params.require(:invite).permit(*allowed)
  end

  def authorize_update
    return unless cannot?(:update, resource) &&
                  cannot?(:edit_invite, parent) &&
                  cannot?(:deactivate_invite, parent)

    fail CanCan::AccessDenied, unauthorized_message(:update, resource)
  end
end
