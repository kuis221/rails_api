class RenameTableKpiSegmentsToKpisSegments < ActiveRecord::Migration
  def change
    remove_index :kpisegments, :kpi_id
    rename_table :kpisegments, :kpis_segments
    add_index :kpis_segments, :kpi_id
  end
end
