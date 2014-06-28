class SatisfactionSurveysController < ApplicationController
  respond_to :js, only: [:create]

  def create
    entry = current_company_user.satisfaction_surveys.find_or_create_by_id_and_session_id(params[:record_id], request.session_options[:id])
    entry.update_attributes(params.permit(:rating, :feedback))
    render json: entry
  end

  private
    def permitted_params
      params.permit(satisfaction_survey: [:rating, :feedback])[:satisfaction_survey]
    end
end
