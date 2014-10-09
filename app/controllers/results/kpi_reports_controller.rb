class Results::KpiReportsController < ApplicationController
  # before_action :authorize_actions

  def index
    campaigns
    @reports = KpiReport.where(company_user_id: current_company_user)
  end

  def report
    KpiReport.create(company_user: current_company_user, params: params.require(:report).permit({ campaign_id: [] }, :year, :month))
    @report = KpiReport.last
    @report.queue!
  end

  def status
    @reports = KpiReport.where(company_user_id: current_company_user, id: params[:report_ids]) if params[:report_ids].any?
  end

  private

  def campaigns
    @campaigns ||= current_company.campaigns.accessible_by_user(current_company_user).order('name ASC')
  end

  # def authorize_actions
  #   authorize! :kpi_report, Campaign
  # end
end
