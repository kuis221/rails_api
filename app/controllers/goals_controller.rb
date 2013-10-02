class GoalsController < FilteredController
  belongs_to :company_user, optional: true, polymorphic: true
  respond_to :js, only: [:create, :new, :update, :edit]
  respond_to :json, only: [:create, :update]
  actions :create, :update, :new, :edit


  private
    def permitted_params
      if respond_to?(:parent?) && parent?
        params.permit(goal: [:value, :parent_id, :parent_type, :kpi_id, :kpis_segment_id, :title, :start_date, :due_date])[:goal]
      else
        params.permit(goal: [:value, :goalable_id, :goalable_type, :parent_id, :parent_type, :kpi_id, :kpis_segment_id, :title, :start_date, :due_date])[:goal]
      end
    end
end