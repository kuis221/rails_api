class ActivitiesController < FilteredController
  belongs_to :venue, polymorphic: true
  respond_to :js, only: [:new, :create]

  def form
    @activity = Activity.new(permitted_params)
    @users = current_company.company_users.active.joins(:user).order('users.first_name ASC')
    render layout: false
  end

  protected
    def permitted_params
      params.permit(activity: [:activity_type_id, {results_attributes: [:id, :form_field_id, :value]}, :company_user_id, :activity_date])[:activity]
    end
end