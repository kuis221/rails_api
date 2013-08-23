# == Schema Information
#
# Table name: event_recaps
#
#  id               :integer          not null, primary key
#  event_id         :integer          not null
#  state            :string(255)
#  bar_tab          :decimal(7, 2)
#  bar_tip          :decimal(7, 2)
#  promo_hours      :decimal(4, 1)
#  number_of_events :integer
#  creator_id       :integer
#  updater_id       :integer
#  created_at       :datetime
#  updated_at       :datetime
#

class Legacy::EventRecap  < Legacy::Record
  belongs_to    :event
  has_one       :program, :through => :event
  has_one       :account, :through => :event
  has_many      :metric_results

  def result_for_metric(metric)
    metric_results.select {|r| r.metric_id == metric.id }.first || metric.metric_results.find_or_initialize_by_event_recap_id(self.id) if metric
  end
end