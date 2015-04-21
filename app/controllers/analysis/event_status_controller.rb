class Analysis::EventStatusController < ApplicationController
  include ExportableController

  respond_to :xls, :pdf, only: :index

  before_action :campaign, except: :index
  before_action :authorize_actions

  helper_method :return_path, :report_group_by, :report_group_permissions

  def report
    @data = if report_group_by == 'campaign'
              Campaign.where(id: campaign.id).promo_hours_graph_data
            elsif report_group_by == 'place'
              campaign.event_status_data_by_areas(current_company_user)
            elsif report_group_by == 'staff'
              campaign.event_status_data_by_staff
            end
  end

  def export_file_name
    "#{controller_name.underscore.downcase}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  protected

  def prepare_collection_for_export
    report
  end

  def list_exportable?
    true
  end

  def campaign
    @campaign ||= current_company.campaigns.find(params[:report][:campaign_id])
  end

  def authorize_actions
    if params[:report] && params[:report][:campaign_id]
      authorize! :event_status_report_campaign, campaign
    else
      authorize! :view_event_status, Campaign
    end
  end

  def return_path
    analysis_path
  end

  def report_group_by
    @_group_by ||= if params[:report] && params[:report][:group_by]
                      params[:report][:group_by]
    else
      if can?(:event_status_campaigns, Campaign)
        'campaign'
      elsif can?(:event_status_places, Campaign)
        'place'
      elsif can?(:event_status_users, Campaign)
        'staff'
      end
    end
  end

  def report_group_permissions
    permissions = []
    permissions.push(%w(Campaign campaign)) if can?(:event_status_campaigns, Campaign)
    permissions.push(%w(Place place)) if can?(:event_status_places, Campaign)
    permissions.push(%w(Staff staff)) if can?(:event_status_users, Campaign)
    permissions
  end
end
