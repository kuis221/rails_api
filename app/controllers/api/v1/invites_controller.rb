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
      param :active, String, desc: "Invitation's status"
    end
  end

  api :GET, '/api/v1/events/:event_id/invites', 'Get a list of invites for an Event'
  param :event_id, :number, required: true, desc: 'Event ID'
  example <<-EOS
  GET /api/v1/events/1223/invites
       [
          {
              "id": 45554,
              "invitees": 23,
              "rsvps_count": 12,
              "attendees": 78,
              "end_at": "2013-11-19T00:49:24-08:00",
              "active": true
          },
          {
              "invitees": 27,
              "rsvps_count": 15,
              "attendees": 34,
              "end_at": "2013-11-19T00:49:16-08:00",
              "active": true
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
    allowed += [:event_id, :venue_id, :attendees, :invitees, :place_reference] if can?(:edit_invite, Event) || can?(:create_invite, Event) || can?(:edit_invite, Venue) || can?(:create_invite, Venue)
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
