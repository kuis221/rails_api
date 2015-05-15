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
#  created_by_id                    :integer
#  updated_by_id                    :integer
#  attended                         :boolean
#

class InviteRsvp < ActiveRecord::Base
  belongs_to :invite

  delegate :place_name, :campaign_name, :invitees, :rsvps_count, :attendees,
           :jameson_locals?, :top_venue?, :event, :area,
           to: :invite

  def self.for_event(event)
    where(invite: event.invites)
  end

  def self.without_locations
    joins('LEFT JOIN zipcode_locations zl ON zl.zipcode=invite_rsvps.zip_code')
      .where('zl.zipcode IS NULL')
  end

  def self.update_zip_code_location(zip_code, latlng)
    point = latlng ? connection.quote("POINT(#{latlng['lng']} #{latlng['lat']})") : 'NULL'
    connection.execute(<<-EOQ)
      INSERT INTO zipcode_locations(zipcode, lonlat)
      VALUES (#{connection.quote(zip_code)},
              #{point})
    EOQ
  end
end
