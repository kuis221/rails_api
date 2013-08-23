# == Schema Information
#
# Table name: metric_results
#
#  id             :integer          not null, primary key
#  event_recap_id :integer          not null
#  metric_id      :integer          not null
#  scalar_value   :decimal(10, 2)   default(0.0)
#  vector_value   :text
#  creator_id     :integer
#  updater_id     :integer
#  created_at     :datetime
#  updated_at     :datetime
#

class MetricResult  < Legacy::Record
  belongs_to :event_recap
  belongs_to :metric

  serialize :vector_value

  def value
    @value ||= metric.fetch_result(self) unless metric.nil?
  end
end