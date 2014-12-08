class RolesController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :xls, :pdf, only: :index

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def update
    update! do |success, _failure|
      success.js do
        render 'update_partial' if params[:partial].present?
      end
    end
  end

  def autocomplete
    buckets = autocomplete_buckets(
      roles: [Role],
      active_state: []
    )
    render json: buckets.flatten
  end

  protected

  def permitted_params
    params.permit(role: [:name, :description, { permissions_attributes: [:id, :enabled, :action, :subject_class, :subject_id] }])[:role]
  end

  def facets
    @facets ||= Array.new.tap do |f|
      f.push build_state_bucket
      f.concat build_custom_filters_bucket
    end
  end
end
