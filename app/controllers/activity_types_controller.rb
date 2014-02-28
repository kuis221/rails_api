class ActivityTypesController < FilteredController
  before_filter :load_campaign, only: [:new, :update, :edit, :create]
  respond_to :js, only: [:new, :create, :edit, :update]

  def load_campaign
    @campaign = current_company.campaigns.find(params[:campaign_id])
  end

  protected
    def permitted_params
      params.permit(activity_type: [{goal_attributes: [:id, :goalable_id, :goalable_type, :activity_type_id, :value, value: []]} ])[:activity_type]
    end
end