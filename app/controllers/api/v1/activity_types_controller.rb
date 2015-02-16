class Api::V1::ActivityTypesController < Api::V1::ApiController
  inherit_resources

  belongs_to :campaign, optional: true

  skip_authorization_check only: [:index, :campaigns]
  skip_authorize_resource only: [:index, :campaigns]

  skip_before_action :verify_authenticity_token,
                     if: proc { |c| c.request.format == 'application/json' }

  api :GET, '/api/v1/campaigns/:campaign_id/activity_types', 'Get a list of contacts for a specific company'
  description <<-EOS
    Returns a full list of the associated activity types for a campaign
  EOS
  example <<-EOS
    GET /api/v1/campaigns/1/activity_types
    [
        {
            "id": 268,
            "name": "Bar Placement"
        },
        {
            "id": 'attendance',
            "name": "Invitation"
        }
    ]
  EOS
  def index
    authorize! :show, parent
    activity_types = collection.pluck(:id, :name)  # Sets @activity_types
    if jbb_feature_enabled? && (parent.nil? || parent.enabled_modules.include?('attendance'))
      activity_types.push [:attendance, 'Invitations']
    end
    activity_types.sort! { |a, b| a[1] <=> b[1] }
    render json: activity_types.map{ |at| { id: at[0], name: at[1] } }
  end

  api :GET, '/api/v1/activity_types/:activity_type_id/campaigns', 'Get a list the campaings for a specific activity type'
  description <<-EOS
    Returns a full list of the associated campaigns for activity type
  EOS
  example <<-EOS
    GET /api/v1/activity_types/1/campaigns
    [
        {
            "id": 268,
            "name": "Bar Placement"
        },
        {
            "id": 'attendance',
            "name": "Invitation"
        }
    ]
  EOS
  def campaigns
    render json: resource.campaigns.active.accessible_by_user(current_company_user).order(:name).map{ |at| { id: at.id, name: at.name } }
  end

  protected

  def begin_of_association_chain
    current_company
  end
end