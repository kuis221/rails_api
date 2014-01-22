class Results::ReportsController < InheritedResources::Base
  respond_to :js, only: [:new, :create]
  def index
  end

  private
    def build_resource_params
      [permitted_params || {}]
    end
    def permitted_params
      params.permit(report: [:name, :description])[:report]
    end
end
