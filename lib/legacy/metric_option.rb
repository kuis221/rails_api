# == Schema Information
#
# Table name: metric_options
#
#  id         :integer          not null, primary key
#  name       :string(255)      not null
#  metric_id  :integer          not null
#  created_at :datetime
#  updated_at :datetime
#  removed    :boolean          default(FALSE)
#

class MetricOption < Legacy::Record
  belongs_to :metric

  scope :not_deleted, lambda{ where({:removed => false}) }

  delegate :name, :to => :metric, :prefix => true
  def qualified_name
    [metric_name, name].join('.')
  end
end
