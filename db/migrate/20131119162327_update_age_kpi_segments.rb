# encoding: utf-8
class UpdateAgeKpiSegments < ActiveRecord::Migration
  def up
    add_column :kpis_segments, :ordering, :integer, limit: 3

    if KpisSegment.find_by_text_and_kpi_id('18 – 24', Kpi.age.id).present?
      Kpi.age.kpis_segments.reorder(:id).each_with_index{|s, i| s.ordering = i; s.save}
      segment = Kpi.age.kpis_segments.detect{|s| s.text == '18 – 24'}
      segment.text = '21 – 24'
      segment.ordering += 1
      segment.save
      Kpi.age.kpis_segments.create({text: '18 – 20', ordering: segment.ordering-1}, without_protection: true)
      Kpi.age.kpis_segments.where('kpis_segments.ordering>?', segment.ordering).update_all('ordering = ordering+1')
    end
  end

  def down
  end
end
