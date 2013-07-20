class CreateGoals < ActiveRecord::Migration
  def change
    create_table :goals do |t|
      t.references :campaign
      t.references :kpi
      t.references :kpis_segment
      t.decimal :value

      t.timestamps
    end
    add_index :goals, :campaign_id
    add_index :goals, :kpi_id
    add_index :goals, :kpis_segment_id
  end
end
