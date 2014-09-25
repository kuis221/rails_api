class SurveysController < FilteredController
  belongs_to :event
  respond_to :js, only: [:new, :create, :edit, :update]
  actions :new, :create, :edit, :update

  include DeactivableHelper

  protected

  def permitted_params
    params.permit(survey: { surveys_answers_attributes: [:id, :brand_id, :question_id, :answer, :kpi_id] })[:survey]
  end
end
