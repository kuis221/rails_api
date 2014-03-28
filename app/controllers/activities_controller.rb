class ActivitiesController < FilteredController
  belongs_to :venue, :event, polymorphic: true, optional: true
  respond_to :js, only: [:new, :create, :edit, :update]
  custom_actions member: [:form]

  include DeactivableHelper

  helper_method :assignable_users, :activity_types

  def form
    build_resource
    @brands = Brand.accessible_by_user(current_company_user.id).order(:name)
    render layout: false
  end

  protected
    def assignable_users
      current_company.company_users.active.joins(:user).includes(:user).order('users.first_name ASC, users.last_name ASC')
    end

    def activity_types
      if parent.is_a?(Event)
        parent.campaign.activity_types.order('activity_types.name ASC')
      else
        current_company.activity_types.active.order(:name)
      end
    end

    # Because there is no collection path, try to return a path
    # based on the current activity or the events_path
    def collection_path
      if params[:id].present?
        url_for(resource.activitable)
      else
        events_path
      end
    end

    def permitted_params
      params.permit(activity: [:activity_type_id, {results_attributes: [:id, :form_field_id, :value, value: []]}, :campaign_id, :company_user_id, :activity_date])[:activity].tap do |whielisted|
        unless whielisted.nil? || whielisted[:results_attributes].nil?
          whielisted[:results_attributes].each do |k, value|
            value[:value] = params[:activity][:results_attributes][k][:value]
          end
        end
      end
    end
end