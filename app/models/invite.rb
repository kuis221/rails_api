# == Schema Information
#
# Table name: invites
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  venue_id      :integer
#  market        :string(255)
#  invitees      :integer          default("0")
#  rsvps_count   :integer          default("0")
#  attendees     :integer          default("0")
#  final_date    :date
#  created_at    :datetime
#  updated_at    :datetime
#  active        :boolean          default("true")
#  area_id       :integer
#  created_by_id :integer
#  updated_by_id :integer
#

class Invite < ActiveRecord::Base
  attr_accessor :selected_campaign_id, :selected_place_id, :selected_date, :selected_time
  belongs_to :event
  belongs_to :venue
  belongs_to :area
  has_one :place, through: :venue
  has_many :individuals, class_name: 'InviteIndividual', inverse_of: :invite

  delegate :name_with_location, :id, :name, to: :place, prefix: true, allow_nil: true
  delegate :jameson_locals?, :top_venue?, to: :venue, allow_nil: true
  delegate :campaign_name, :campaign_id, to: :event, prefix: false, allow_nil: true

  validates :event, presence: true
  validates :venue, presence: true, unless: :market_level?
  validates :area, presence: true, if: :market_level?
  validates :invitees, presence: true, numericality: true

  scope :active, -> { where active: true }

  before_validation :set_event_from_selections

  ATTENDANCE_DISPLAY_BY_TYPES = {
    '1' => 'venue',
    '2' => 'market'
  }

  def place_reference=(value)
    @place_reference = value
    return unless value && value.present?
    place = find_place_by_reference(value)
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

  def selected_place_id=(value)
    return unless value && value.present?
    @selected_place = find_place_by_reference(value)
    return unless @selected_place.present?
    @selected_place_id = @selected_place.id
  end

  def selected_place_reference
    return @selected_place.name_with_location if @selected_place.present?
    event.place_name_with_location if event.present?
  end

  def find_place_by_reference(value)
    place =
      if value.to_s =~ /^[0-9]+$/
        Place.find(value)
      else
        reference, place_id = value.split('||')
        Place.load_by_place_id(place_id, reference)
      end
    place.save unless place.persisted?
    place
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  private

  def market_level?
    area_id.present?
  end

  # On new invitation from a venue form, the user selects
  # different event attributes instead of a event id
  def set_event_from_selections
    return if event_id.present? || !event_params_present?
    self.event = Campaign.find(selected_campaign_id).events.find_by(
      place_id: selected_place_id,
      local_start_at: Timeliness.parse("#{selected_date} #{selected_time}", zone: 'UTC'))
    return if self.event.present?
    errors.add :selected_place_id, 'a event could be found for this venue on this date'
  end


  def event_params_present?
    @selected_campaign_id && @selected_place_id &&
      @selected_date && @selected_time
  end
end
