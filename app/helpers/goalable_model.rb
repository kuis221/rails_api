module GoalableModel

  def self.included(receiver)
    if receiver < ActiveRecord::Base
      receiver.has_many :goals, as: :goalable do
        def for_kpis(kpis)
          kpis.map do |kpi|
            for_kpi(kpi)
          end
        end

        def for_kpi(kpi)
          goal = select{|r| r.kpi_id == kpi.id  && r.kpis_segment_id.nil? }.first || self.build({kpi: kpi, value: nil}, without_protection: true)
          goal.kpi = kpi
          goal
        end

        def for_kpis_segments(kpi)
          kpi.kpis_segments.map do |segment|
            goal = select{|r|  r.kpis_segment_id == segment.id }.first || self.build({kpi: kpi, kpis_segment: segment, value: nil}, without_protection: true)
            goal.kpi = kpi
            goal.kpis_segment = segment
            goal
          end
        end

        def for_activity_types(activity_types)
          activity_types.map do |activity_type|
            for_activity_type(activity_type)
          end
        end

        def for_activity_type(activity_type)
          goal = all.select{|r| r.activity_type_id == activity_type.id}.first || self.build({activity_type: activity_type, value: nil}, without_protection: true)
          goal.activity_type = activity_type
          goal
        end
      end

      receiver.has_many :children_goals, class_name: 'Goal', as: :parent
    end
  end
end