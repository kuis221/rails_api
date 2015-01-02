# == Schema Information
#
# Table name: invites
#
#  id                               :integer          not null, primary key
#  invitable_id                     :integer
#  invitable_type                   :string(255)
#  venue_id                         :integer
#  invitees                         :integer
#  rsvps                            :integer
#  attendees                        :integer
#  final_date                       :date
#  event_date                       :date
#  registrant_id                    :integer
#  date_added                       :date
#  email                            :string(255)
#  mobile_phone                     :string(255)
#  mobile_signup                    :boolean
#  first_name                       :string(255)
#  last_name                        :string(255)
#  attended_previous_bartender_ball :boolean
#  opt_in_to_future_communication   :boolean
#  primary_registrant_id            :integer
#  bartender_how_long               :string(255)
#  bartender_role                   :string(255)
#  created_at                       :datetime
#  updated_at                       :datetime
#

require 'rails_helper'

RSpec.describe Invite, :type => :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
