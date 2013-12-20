class Results::KpiReportController < ApplicationController
  #before_filter :authorize_actions

  def index
    campaigns
    @reports = Report.scoped_by_company_user_id(current_company_user)
  end

  def report
    Report.create({type:'Report::Kpi', company_user: current_company_user, params: params.require(:report).permit({campaign_id: []}, :year, :month)}, without_protection: true)
    @report = Report.last
    @report.queue!
  end

  def status
    @reports = Report.scoped_by_company_user_id(current_company_user).where(id: params[:report_ids]) if params[:report_ids].any?
  end

  private
    def campaigns
      @campaigns ||= current_company.campaigns.accessible_by_user(current_company_user).order('name ASC')
    end

    # def authorize_actions
    #   authorize! :kpi_report, Campaign
    # end
end