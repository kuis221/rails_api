class Analysis::CampaignSummaryReportController < ApplicationController

  respond_to :xls, :pdf, only: :index

  helper_method :return_path

  def report
    @campaign ||= current_company.campaigns.find(params[:report][:campaign_id]) if params[:report] && params[:report][:campaign_id].present?
    render layout: false
  end

  protected

  def return_path
    analysis_path
  end
end