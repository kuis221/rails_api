class ActivityTypesController < FilteredController
  before_filter :load_campaign, only: [ :set_goal]
  respond_to :js, only: [:new, :create, :edit, :update, :set_goal]
  respond_to :json, only: [:show, :update]
  belongs_to :company, :campaign, optional: true

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

  def update
    update! do |success, failure|
      success.js { render }
      success.json { render json: {result: 'OK' } }
      failure.json { render json: {result: 'KO', message: resource.errors.full_messages.join('<br />') } }
    end
  end

  def set_goal
    @activity_type = ActivityType.find(params[:activity_type_id])
  end

  protected

    def permitted_params
      params.permit(activity_type: [
        :name, :description,
        {form_fields_attributes: [
          :id, :name, :field_type, :ordering, :required, :_destroy,
          {settings: [:description, :range_min, :range_max, :range_format]},
          {options_attributes: [:id, :name, :_destroy, :ordering]},
          {statements_attributes: [:id, :name, :_destroy, :ordering]}]},
        {goals_attributes: [:id, :goalable_id, :goalable_type, :activity_type_id, :value, value: []]}
      ])[:activity_type]
    end

    def facets
      @facets ||= Array.new.tap do |f|
        # select what params should we use for the facets search
        f.push(label: "Active State", items: ['Active', 'Inactive'].map{|x| build_facet_item({label: x, id: x, name: :status, count: 1}) })
      end
    end
end