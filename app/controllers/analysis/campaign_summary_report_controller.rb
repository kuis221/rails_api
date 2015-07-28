class Analysis::CampaignSummaryReportController < ApplicationController

  respond_to :xls, :pdf, only: :export_results

  helper_method :return_path
  before_action :set_cache_header, only: [:export_results]

  def export_results
    @campaign ||= current_company.campaigns.find(params[:campaign]) if params[:campaign].present?
    @event_scope = results_scope

    respond_to do |format|
      format.pdf do
        render pdf: pdf_form_file_name,
               layout: 'application.pdf',
               disposition: 'attachment',
               show_as_html: params[:debug].present?
      end
      format.html do
        render layout: 'application.pdf',
               disposition: 'attachment',
               show_as_html: params[:debug].present?
      end
    end
  end

  def report
    @campaign ||= current_company.campaigns.find(params[:report][:campaign_id]) if params[:report] && params[:report][:campaign_id].present?
    @event_scope = results_scope
    render layout: false
  end

  def results_scope
    scope = Event.where(active: true)
  end

  protected

  def return_path
    analysis_path
  end

  private

  def pdf_form_file_name
    "#{@campaign.name.parameterize}-#{Time.now.strftime('%Y%m%d%H%M%S')}"
  end

  def set_cache_header
    response.headers['Cache-Control']='private, max-age=0, no-cache'
  end
end