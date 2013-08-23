#TODO: Consider deleting the migration after a while

class UpdateAgeSegments < ActiveRecord::Migration
  def change
    age_kpi = Kpi.age
    if age_kpi.kpis_segments.count  == 15 # Only do if using the old set of segments
      age_kpi.kpis_segments.destroy_all

      ['< 12', '12 – 17', '18 – 24', '25 – 34', '35 – 44', '45 – 54', '55 – 64', '65+'].each do |segment|
        age_kpi.kpis_segments.create(text: segment)
      end
    end
  end
end
