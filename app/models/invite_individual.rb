# == Schema Information
#
# Table name: invite_individuals
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

class InviteIndividual < ActiveRecord::Base
  track_who_does_it

  belongs_to :invite, inverse_of: :individuals
  accepts_nested_attributes_for :invite

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true

  delegate :place_name, :campaign_name, :invitees, :rsvps_count, :attendees,
           :jameson_locals?, :top_venue?, :event, :area,
           to: :invite

  scope :active, -> { where active: true }

  after_create :increase_invite_counters

  def self.left_join_with_places
    joins(:invite)
      .joins('LEFT JOIN venues ON venues.id=invites.venue_id')
      .joins('LEFT JOIN places ON places.id=venues.place_id')
  end

  def self.for_event(event)
    where(invite: event.invites)
  end

  def name
    [first_name, last_name].compact.join ' '
  end

  def self.without_locations
    joins('LEFT JOIN zipcode_locations zl ON zl.zipcode=invite_rsvps.zip_code')
      .where('zl.zipcode IS NULL')
  end

  def self.update_zip_code_location(zip_code)
    latlng = get_latlng_for_zip_code(zip_code)
    neighborhood_id = find_closest_neighborhood(latlng)
    point = latlng ? connection.quote("POINT(#{latlng['lng']} #{latlng['lat']})") : 'NULL'
    connection.execute(<<-EOQ)
      INSERT INTO zipcode_locations(zipcode, lonlat, neighborhood_id)
      VALUES (#{connection.quote(zip_code)},
              #{point},
              #{neighborhood_id || 'NULL'})
    EOQ
  end

  def self.get_latlng_for_zip_code(zipcode)
    data = JSON.parse(open(
            'https://maps.googleapis.com/maps/api/geocode/json?components='\
            "postal_code:#{zipcode}|country:US&sensor=true").read)
    data['results'].first['geometry']['location'] rescue nil
  end

  def self.find_closest_neighborhood(latlng)
    return unless latlng
    point = "POINT(#{latlng['lng']} #{latlng['lat']})"
    id = Neighborhood.where('ST_Intersects(ST_GeomFromText(?), geog)', point).pluck(:gid).first
    id ||= Neighborhood.order("ST_Distance(ST_GeomFromText('#{point}'), geog) ASC").pluck(:gid).first
    id
  end

  def increase_invite_counters
    invite.increment! :invitees
    invite.increment! :rsvps_count if rsvpd?
    invite.increment! :attendees if attended?
  end
end
