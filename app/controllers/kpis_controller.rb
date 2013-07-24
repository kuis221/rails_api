class KpisController < FilteredController
  before_filter :load_campaign, only: [:new, :update, :edit, :create]
  respond_to :js, only: [:new, :create, :edit, :update]

  def load_campaign
    @campaign = current_company.campaigns.find(params[:campaign_id])
  end
end