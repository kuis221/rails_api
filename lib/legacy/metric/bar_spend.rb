# == Schema Information
#
# Table name: metrics
#
#  id          :integer          not null, primary key
#  type        :string(32)
#  brand_id    :integer
#  program_id  :integer
#  name        :string(255)
#  style       :string(255)
#  optional_id :integer
#  active      :boolean          default(TRUE)
#  creator_id  :integer
#  updater_id  :integer
#  created_at  :datetime
#  updated_at  :datetime
#

# INTERNAL USE - stores data in EventRecap
require 'legacy/metric/tab'
class Metric::BarSpend < Metric::Tab
  validates_presence_of :program_id, :message => "must be a program metric"
  validates_uniqueness_of :type, :scope => :program_id

  def field_type_symbol
    '!BT'
  end

  def store_result(value, result)
    v = super # call super to ALSO store the data in the result - TODO does this make sense?
    result.event_recap.update_attributes(:bar_tab => v[TAB], :bar_tip => v[TIP])  if result.event_recap
    v
  end
  def fetch_result(result)
    v = {}
    if result.event_recap
      v[TAB] = result.event_recap.read_attribute(:bar_tab).to_f
      v[TIP] = result.event_recap.read_attribute(:bar_tip).to_f
      v[TOTAL] = v[TAB] + v[TIP]
    end
    v
  end
  def report_columns
    ["#{name} Tab", "#{name} Tip", "#{name} Total"]
  end
  def result_hash(result)
    v = cast_value(result.value)
    {"#{name} Tab" => v[TAB], "#{name} Tip" => v[TIP], "#{name} Total" => v[TOTAL] }
  end
end
