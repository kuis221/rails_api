class ActivityTypesController < FilteredController
  before_filter :load_campaign, only: [:edit, :update]
  respond_to :js, only: [:edit, :update]
  
  helper_method :describe_filters

  def load_campaign
    @campaign = current_company.campaigns.find(params[:campaign_id])
  end
  
  def autocomplete
    buckets = autocomplete_buckets({
        activity_types: [ActivityType]
      })
    render :json => buckets.flatten
  end
  
  protected
  def permitted_params
    params.permit(activity_type: [{goal_attributes: [:id, :goalable_id, :goalable_type, :activity_type_id, :value, value: []]} ])[:activity_type]
  end
    
  def facets
    @facets ||= Array.new.tap do |f|
      # select what params should we use for the facets search
      f.push(label: "Active State", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
    end
  end
end