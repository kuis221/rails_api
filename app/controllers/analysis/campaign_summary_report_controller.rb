class Analysis::CampaignSummaryReportController < ApplicationController

  helper_method :return_path

  protected

  def return_path
    analysis_path
  end
end