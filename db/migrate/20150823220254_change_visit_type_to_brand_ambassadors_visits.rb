class ChangeVisitTypeToBrandAmbassadorsVisits < ActiveRecord::Migration
  def up
    BrandAmbassadors::Visit.where(visit_type: 'brand_program').update_all(visit_type: 'Brand Program')
    BrandAmbassadors::Visit.where(visit_type: 'pto').update_all(visit_type: 'PTO')
    BrandAmbassadors::Visit.where(visit_type: 'market_visit').update_all(visit_type: 'Formal Market Visit')
    BrandAmbassadors::Visit.where(visit_type: 'local_market_request').update_all(visit_type: 'Local Market Request')
  end
  def down
    BrandAmbassadors::Visit.where(visit_type: 'Brand Program').update_all(visit_type: 'brand_program')
    BrandAmbassadors::Visit.where(visit_type: 'PTO').update_all(visit_type: 'pto')
    BrandAmbassadors::Visit.where(visit_type: 'Formal Market Visit').update_all(visit_type: 'market_visit')
    BrandAmbassadors::Visit.where(visit_type: 'Local Market Request').update_all(visit_type: 'local_market_request')
  end
end
