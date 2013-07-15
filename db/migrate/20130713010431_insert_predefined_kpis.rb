class InsertPredefinedKpis < ActiveRecord::Migration
  def up
    Kpi.create({name: 'Promo Hours', kpi_type: 'promo_hours', description: 'Total duration of events', capture_mechanism: '', company_id: nil, 'module' => ''}, without_protection: true)
    Kpi.create({name: 'Events', kpi_type: 'events_count', description: 'Number of events executed', capture_mechanism: '', company_id: nil, 'module' => ''}, without_protection: true)
    Kpi.create({name: 'Impressions', kpi_type: 'number', description: 'Total number of consumers who come in contact with an event', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach'}, without_protection: true)
    Kpi.create({name: 'Interactions', kpi_type: 'number', description: 'Total number of consumers who directly interact with an event', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach'}, without_protection: true)
    Kpi.create({name: 'Samples', kpi_type: 'number', description: 'Number of consumers who try a product sample', capture_mechanism: 'integer', company_id: nil, 'module' => 'consumer_reach'}, without_protection: true)
    Kpi.create({name: 'Gender', kpi_type: 'percentage', description: 'Number of consumers who try a product sample', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics'}, without_protection: true)
    Kpi.create({name: 'Age', kpi_type: 'percentage', description: 'Percentage of attendees who are within a certain age range', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics'}, without_protection: true)
    Kpi.create({name: 'Ethnicity/Race', kpi_type: 'percentage', description: 'Percentage of attendees who are of a certain ethnicity or race', capture_mechanism: 'integer', company_id: nil, 'module' => 'demographics'}, without_protection: true)
    Kpi.create({name: 'Cost', kpi_type: 'number', description: 'Total cost of an event', capture_mechanism: 'decimal', company_id: nil, 'module' => 'expenses'}, without_protection: true)
    Kpi.create({name: 'Photos', kpi_type: 'photos', description: 'Total number of photos uploaded to an event', capture_mechanism: '', company_id: nil, 'module' => 'videos'}, without_protection: true)
    Kpi.create({name: 'Videos', kpi_type: 'videos', description: 'Total number of photos uploaded to an event', capture_mechanism: '', company_id: nil, 'module' => 'photos'}, without_protection: true)
    Kpi.create({name: 'Surveys', kpi_type: 'number', description: 'Total number of surveys completed for a campaign', capture_mechanism: 'integer', company_id: nil, 'module' => 'surveys'}, without_protection: true)
    Kpi.create({name: 'Competitive Analysis', kpi_type: 'number', description: 'Total number of competitive analyses created for a campaign', capture_mechanism: 'integer', company_id: nil, 'module' => 'competitive_analysis'}, without_protection: true)
  end
  def down
    Kpi.delete_all
  end
end
