class Results::EventStatusController < ApplicationController
  before_action :campaign, except: :index
  before_action :authorize_actions

  helper_method :return_path, :report_group_by

  def report
    @data = if report_group_by == 'campaign'
              Campaign.where(id: campaign.id).promo_hours_graph_data
    elsif report_group_by == 'place'
              @campaign.event_status_data_by_areas(current_company_user)
    elsif report_group_by == 'staff'
              @campaign.event_status_data_by_staff
    end
  end

  private

  def campaign
    @campaign ||= current_company.campaigns.find(params[:report][:campaign_id])
  end

  def authorize_actions
    if params[:report] && params[:report][:campaign_id]
      authorize! :event_status_report_campaign, campaign
    else
      authorize! :event_status, Campaign
    end
  end

  def return_path
    results_reports_path
  end

  def report_group_by
    @_view_mode ||= if params[:report] && params[:report][:group_by]
                      params[:report][:group_by]
    else
      'campaign'
    end
  end
end
