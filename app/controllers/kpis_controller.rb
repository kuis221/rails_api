class KpisController < FilteredController
  before_filter :load_campaign, only: [:new, :update, :edit, :create]
  respond_to :js, only: [:new, :create, :edit, :update]

  def load_campaign
    @campaign = current_company.campaigns.find(params[:campaign_id])
  end

  protected
    def permitted_params
      goals_attributes = [:id, :goalable_id, :goalable_type, :value, :kpis_segment_id, :kpi_id]
      common_params = [{kpis_segments_attributes: [:id, :text, :_destroy, {goals_attributes: goals_attributes}]}, {goals_attributes: goals_attributes}]

      # Allow only certain params for global KPIs like impresssions, interactions, gender, etc
      if params[:id].nil? || params[:id].empty? || !Kpi.global.select('id').map(&:id).include?(params[:id].to_i)
        params.permit(kpi: [:name, :description, :kpi_type, :capture_mechanism] + common_params)[:kpi]
      else
        params.permit(kpi: common_params)[:kpi]
      end
    end
end