class Results::EventStatusController < ApplicationController
  respond_to :xls, :pdf, only: :index

  before_action :campaign, except: :index
  before_action :authorize_actions

  helper_method :return_path, :report_group_by, :report_group_permissions

  def index
    if request.format.xls? || request.format.pdf?
      @export = ListExport.create(
        controller: self.class.name,
        params: params,
        url_options: url_options,
        export_format: params[:format],
        company_user: current_company_user)
      if @export.new?
        @export.queue!
      end
      render template: 'application/new_export', formats: [:js]
    end
  end

  def report
    @data = if report_group_by == 'campaign'
              Campaign.where(id: campaign.id).promo_hours_graph_data
            elsif report_group_by == 'place'
              campaign.event_status_data_by_areas(current_company_user)
            elsif report_group_by == 'staff'
              campaign.event_status_data_by_staff
            end
  end

  def export_list(export)
    report
    Slim::Engine.with_options(pretty: true, sort_attrs: false, streaming: false) do
      render_to_string :index, handlers: [:slim], formats: export.export_format.to_sym, layout: 'application'
    end
  end

  def export_file_name
    "#{controller_name.underscore.downcase}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  private

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
    results_reports_path
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
