class AddKpiIdToEventResultsTable < ActiveRecord::Migration
  def change
    add_column :event_results, :kpi_id, :integer
    add_index :event_results, :kpi_id
    execute 'UPDATE "event_results" SET kpi_id = campaign_form_fields.kpi_id FROM  "campaign_form_fields" WHERE "campaign_form_fields"."id" = "event_results"."form_field_id" AND (event_results.kpi_id is null and campaign_form_fields.kpi_id is not null)'
  end
end
