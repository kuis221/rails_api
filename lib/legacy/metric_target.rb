# == Schema Information
#
# Table name: metric_targets
#
#  id            :integer          not null, primary key
#  metric_id     :integer          not null
#  program_id    :integer          not null
#  market_id     :integer
#  event_type_id :integer
#  value         :decimal(10, 2)   default(0.0)
#  creator_id    :integer
#  updater_id    :integer
#  created_at    :datetime
#  updated_at    :datetime
#

# MetricTargets are to be referred to as "Goals" externally.
class MetricTarget < Legacy::Record
  belongs_to :metric
end
