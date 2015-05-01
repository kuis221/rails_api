class RolesController < FilteredController
  respond_to :js, only: [:new, :create, :edit, :update]
  respond_to :xls, :pdf, only: :index

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableController

  def update
    update! do |success, _failure|
      success.js do
        render 'update_partial' if params[:partial].present?
      end
    end
  end

  protected

  def permitted_params
    params.permit(role: [:name, :description,
                         { permissions_attributes: [:id, :mode, :action, :subject_class, :subject_id] }
                        ])[:role]
  end
end
