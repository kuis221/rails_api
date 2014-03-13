class Results::ReportsController < InheritedResources::Base
  respond_to :js, only: [:new, :create, :edit, :update, :share_form, :show]

  load_and_authorize_resource except: [:index]

  # This helper provide the methods to activate/deactivate the resource
  include DeactivableHelper

  def index
    @reports = current_company.reports.active.accessible_by_user(current_company_user).order('reports.name ASC')
  end

  def preview
    @report = Report.new(permitted_params.merge(company_id: current_company.id, name: resource.name))
  end

  def build
  end

  def share_form
    @sharing_collection = ActiveRecord::Base.connection.select_all("
      #{current_company.company_users.select('company_users.id, users.first_name || \' \' || users.last_name as name, \'company_user\' as type').active.joins(:user).to_sql}
      UNION ALL
      #{current_company.roles.select('roles.id, roles.name, \'role\' as type').active.to_sql}
      UNION ALL
      #{current_company.teams.select('teams.id, teams.name, \'team\' as type').active.to_sql}
      ORDER BY name ASC
    ").map{|r| [r['name'], "#{r['type']}:#{r['id']}", {class: r['type']}] }
  end

  private
    def build_resource_params
      [permitted_params || {}]
    end

    def permitted_params
      params.permit(report: [
        :name, :description, :sharing, {sharing_selections: []},
        { rows: [:field, :label, :aggregate] },
        { columns: [:field, :label] },
        { values: [:field, :label, :aggregate, :display] },
        { filters: [:field, :label] }
      ])[:report] || {}
    end
end
