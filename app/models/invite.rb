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
#  created_at  :datetime
#  updated_at  :datetime
#

class Invite < ActiveRecord::Base
  belongs_to :event
  belongs_to :venue
  has_one :place, through: :venue
  has_many :rsvps, class_name: 'InviteRsvp'

  delegate :name_with_location, :id, :name, to: :place, prefix: true, allow_nil: true
  delegate :campaign_name, to: :event, prefix: false

  validates :venue, presence: true
  validates :event, presence: true
  validates :invitees, presence: true, numericality: true

  def place_reference=(value)
    @place_reference = value
    return unless value && value.present?
    place =
      if value =~ /^[0-9]+$/
        Place.find(value)
      else
        reference, place_id = value.split('||')
        Place.load_by_place_id(place_id, reference)
      end
    place.save unless place.persisted?
    return unless place.present?
    if place.persisted?
      self.venue = Venue.find_or_initialize_by(place_id: place.id, company_id: Company.current.id)
    else
      self.venue = Venue.new(place: place.id, company: Company.current)
    end
  end

  def place_reference
    if place_id.present?
      place_id
    else
      "#{place.reference}||#{place.place_id}" if place.present?
    end
  end
end
