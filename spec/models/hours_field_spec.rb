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

require 'rails_helper'

RSpec.describe HoursField, :type => :model do
  it { is_expected.to belong_to(:venue) }
end
