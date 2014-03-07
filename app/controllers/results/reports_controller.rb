class Results::ReportsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update, :share]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def index
    @reports = current_company.reports.active.order('reports.name ASC')
  end

  def preview
    @report = Report.new(permitted_params.merge(company_id: current_company.id, name: resource.name))
  end

  def build
  end

  def share_form
  end

  private
    def build_resource_params
      [permitted_params || {}]
    end
    def permitted_params
      params.permit(report: [
        :name, :description,
        { rows: [:field, :label, :aggregate] },
        { columns: [:field, :label] },
        { values: [:field, :label, :aggregate, :display] },
        { filters: [:field, :label] }
      ])[:report] || {}
    end
end
