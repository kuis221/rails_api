# == Schema Information
#
# Table name: invite_rsvps
#
#  id                               :integer          not null, primary key
#  invite_id                        :integer
#  registrant_id                    :integer
#  date_added                       :date
#  email                            :string(255)
#  mobile_phone                     :string(255)
#  mobile_signup                    :boolean
#  first_name                       :string(255)
#  last_name                        :string(255)
#  attended_previous_bartender_ball :string(255)
#  opt_in_to_future_communication   :boolean
#  primary_registrant_id            :integer
#  bartender_how_long               :string(255)
#  bartender_role                   :string(255)
#  created_at                       :datetime
#  updated_at                       :datetime
#  date_of_birth                    :string(255)
#  zip_code                         :string(255)
#

class InviteRsvp < ActiveRecord::Base
  belongs_to :invite

  delegate :place_name, :campaign_name, :invitees, :rsvps_count, :attendees,
           :jameson_locals?, :top_venue?, :event, :area,
           to: :invite
end
