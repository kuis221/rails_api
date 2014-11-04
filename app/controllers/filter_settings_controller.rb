class FilterSettingsController < InheritedResources::Base
  respond_to :js, only: [:index, :new, :create, :update]

  actions :index, :new, :create, :update

  private

  def build_resource
    if action_name == 'new'
      @filter_setting ||= current_company_user.filter_settings.find_or_initialize_by(apply_to: params[:apply_to])
    else
      super
    end
  end

  def begin_of_association_chain
    current_company_user
  end

  def build_resource_params
    [permitted_params || {}]
  end

  def permitted_params
    params.permit(filter_setting: [:id, :apply_to, settings: []])[:filter_setting].tap do |p|
      p[:settings] ||= []
    end if params[:filter_setting]
  end
end
