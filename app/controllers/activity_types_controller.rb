class ActivityTypesController < FilteredController
  before_filter :load_campaign, only: [ :set_goal]
  respond_to :js, only: [:new, :create, :edit, :update, :set_goal]
  belongs_to :company, optional: true
  
  helper_method :describe_filters
  
  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def load_campaign
    @campaign = current_company.campaigns.find(params[:campaign_id])
  end
  
  def autocomplete
    buckets = autocomplete_buckets({
        activity_types: [ActivityType]
      })
    render :json => buckets.flatten
  end
  
  def set_goal
      @activity_type = ActivityType.find(params[:activity_type_id])
    end
  
  protected
  def permitted_params
    params.permit(activity_type: [:name, :description, {goal_attributes: [:id, :goalable_id, :goalable_type, :activity_type_id, :value, value: []]}])[:activity_type]
  end
    
  def facets
    @facets ||= Array.new.tap do |f|
      # select what params should we use for the facets search
      f.push(label: "Active State", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
    end
  end
end