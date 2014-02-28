class ActivityTypesController < FilteredController
  before_filter :load_campaign, only: [:edit, :update]
  respond_to :js, only: [:edit, :update]

  def load_campaign
    @campaign = current_company.campaigns.find(params[:campaign_id])
  end

  protected
    def permitted_params
      params.permit(activity_type: [{goal_attributes: [:id, :goalable_id, :goalable_type, :activity_type_id, :value, value: []]} ])[:activity_type]
    end
end