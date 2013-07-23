class CreateEventResutsTable < ActiveRecord::Migration
  def change
    create_table :event_results do |t|
      t.references :form_field
      t.references :event
      t.references :kpis_segment
      t.text :value
      t.decimal :scalar_value, :precision => 10, :scale => 2, :default => 0

      t.timestamps
    end
  end
end
