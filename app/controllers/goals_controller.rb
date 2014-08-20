class GoalsController < FilteredController
  belongs_to :company_user, optional: true, polymorphic: true
  respond_to :js, only: [:create, :new, :update, :edit]
  respond_to :json, only: [:create, :update]
  actions :create, :update, :new, :edit

  #skip_authorize_resource only: [:create, :update]
  #before_action :authorize_actions, only: [:create, :update]

  private
    def permitted_params
      if respond_to?(:parent?) && parent?
        params.permit(goal: [:value, :parent_id, :parent_type, :kpi_id, :kpis_segment_id, :activity_type_id, :title, :start_date, :due_date])[:goal]
      else
        params.permit(goal: [:value, :goalable_id, :goalable_type, :parent_id, :parent_type, :kpi_id, :kpis_segment_id, :activity_type_id, :title, :start_date, :due_date])[:goal]
      end
    end

    def authorize_actions
      authorize!(:show, params[:goal][:parent_type].constantize) # if params[:parent_type].present?
    end
end