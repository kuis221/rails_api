class UpdateSurveysModuleKpi < ActiveRecord::Migration
  def up
    execute "UPDATE kpis set kpi_type='surveys', capture_mechanism=null where name='Surveys' and company_id is null"
  end

  def down
    execute "UPDATE kpis set kpi_type='number', capture_mechanism='number' where name='Surveys' and company_id is null"
  end
end
