# == Schema Information
#
# Table name: hours_fields
#
#  id         :integer          not null, primary key
#  venue_id   :integer
#  day        :integer
#  hour_open  :string(255)
#  hour_close :string(255)
#  created_at :datetime
#  updated_at :datetime
#

class HoursField < ActiveRecord::Base
  belongs_to :venue
end
