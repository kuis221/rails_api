module GoalableModel

  def self.included(receiver)
    if receiver < ActiveRecord::Base
      receiver.has_many :goals, as: :goalable do
        def for_kpis(kpis, build=true)
          kpis.map do |kpi|
            for_kpi(kpi, build)
          end.compact
        end

        def for_kpi(kpi, build=true)
          if goal = select{|r| r.kpi_id == kpi.id  && r.kpis_segment_id.nil? }.first || (build ? self.build(kpi: kpi, value: nil) : nil )
            goal.kpi = kpi
            goal
          end
        end

        def for_kpis_segments(kpi, build=true)
          kpi.kpis_segments.map do |segment|
            if goal = select{|r|  r.kpis_segment_id == segment.id }.first || (build ? self.build(kpi: kpi, kpis_segment: segment, value: nil) : nil)
              goal.kpi = kpi
              goal.kpis_segment = segment
              goal
            end
          end.compact
        end

        def for_activity_types(activity_types, build=true)
          activity_types.map do |activity_type|
            for_activity_type(activity_type, build)
          end.compact
        end

        def for_activity_type(activity_type, build=true)
          if goal = select{|r| r.activity_type_id == activity_type.id }.first || (build ? self.build(activity_type: activity_type, value: nil) : nil)
            goal.activity_type = activity_type
            goal
          end
        end
      end

      receiver.has_many :children_goals, class_name: 'Goal', as: :parent
    end
  end
end