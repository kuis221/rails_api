module GoalableModel

  def self.included(receiver)
    if receiver < ActiveRecord::Base
      receiver.has_many :goals, as: :goalable do
        def for_kpis(kpis)
          kpis.map do |kpi|
            goal = all.select{|r| r.kpi_id == kpi.id  && r.kpis_segment_id.nil? }.first || self.build({kpi: kpi, value: nil}, without_protection: true)
            goal.kpi = kpi
            goal
          end
        end

        def for_kpis_segments(kpi)
          kpi.kpis_segments.map do |segment|
            goal = self.includes(:kpis_segment).select{|r|  r.kpis_segment_id == segment.id }.first || self.build({kpi: kpi, kpis_segment: segment, value: nil}, without_protection: true)
            goal.kpi = kpi
            goal.kpis_segment = segment
            goal
          end
        end
      end
    end
  end
end