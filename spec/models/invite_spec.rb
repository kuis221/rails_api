# == Schema Information
#
# Table name: invites
#
#  id          :integer          not null, primary key
#  event_id    :integer
#  venue_id    :integer
#  market      :string(255)
#  invitees    :integer          default(0)
#  rsvps_count :integer          default(0)
#  attendees   :integer          default(0)
#  final_date  :date
#  event_date  :date
#  created_at  :datetime
#  updated_at  :datetime
#

require 'rails_helper'

RSpec.describe Invite, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
