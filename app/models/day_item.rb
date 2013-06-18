# == Schema Information
#
# Table name: day_items
#
#  id          :integer          not null, primary key
#  day_part_id :integer
#  start_time  :time
#  end_time    :time
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

class DayItem < ActiveRecord::Base
  attr_accessible :start_time, :end_time

  validates :day_part_id, presence: true, numericality: true
  validates :start_time, presence: true

  validates_time :start_time
  validates_time :end_time, on_or_after: :start_time, allow_nil: true, allow_blank: true

  belongs_to :day_part

  def label
    description = describe_times
    description.strip!
    # Make sure the first letter is in upper case without changing the others
    description = description.slice(0,1).capitalize + description.slice(1..-1) unless description.empty?
    description
  end

  private
    def describe_times
      if start_time and end_time
        "From #{start_time.to_s(:time_only)} to #{end_time.to_s(:time_only)}"
      elsif start_time
        "At #{start_time.to_s(:time_only)}"
      else
        ""
      end
    end
end
