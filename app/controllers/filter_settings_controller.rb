class FilterSettingsController < InheritedResources::Base
  respond_to :js, only: [:index, :new, :create, :update]

  actions :index, :new, :create, :update

  private

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    params.permit(filter_setting: [:id, :company_user_id, :apply_to, settings: []])[:filter_setting].tap do |p|
      p[:settings] ||= []
    end if params[:filter_setting]
  end
end
