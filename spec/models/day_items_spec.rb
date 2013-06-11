# == Schema Information
#
# Table name: day_items
#
#  id          :integer          not null, primary key
#  day_part_id :integer
#  start_time  :string(255)
#  end_time    :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#

require 'spec_helper'

describe DayItem do
  pending "add some examples to (or delete) #{__FILE__}"
end
