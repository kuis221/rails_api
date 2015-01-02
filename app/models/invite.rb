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

class Invite < ActiveRecord::Base
  belongs_to :invitable, polymorphic: true
  belongs_to :venue
  has_one :place, through: :venue

  delegate :name_with_location, :id, :name, to: :place, prefix: true, allow_nil: true

  validates :venue, presence: true
  validates :invitable, presence: true
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
