# == Schema Information
#
# Table name: areas
#
#  id                            :integer          not null, primary key
#  name                          :string(255)
#  description                   :text
#  active                        :boolean          default(TRUE)
#  company_id                    :integer
#  created_by_id                 :integer
#  updated_by_id                 :integer
#  created_at                    :datetime         not null
#  updated_at                    :datetime         not null
#  common_denominators           :text
#  common_denominators_locations :integer          default([]), is an Array
#

class Area < ActiveRecord::Base
  include GoalableModel
  track_who_does_it

  scoped_to_company

  # Defines the method do_search
  include SolrSearchable

  validates :name, presence: true, uniqueness: { scope: :company_id }
  validates :company_id, presence: true

  has_many :placeables, as: :placeable, inverse_of: :placeable # , after_add: :update_common_denominators, after_remove: :update_common_denominators
  has_many :places, through: :placeables

  has_many :areas_campaigns, inverse_of: :area
  has_many :campaigns, -> { order('name ASC') }, through: :areas_campaigns

  scope :active, -> { where(active: true) }
  scope :not_in_venue, ->(place) { where('areas.id not in (?)', place.area_ids + [0]) }

  def self.accessible_by_user(company_user)
    if company_user.is_admin?
      in_company(company_user.company_id)
    else
      in_company(company_user.company_id).where(
        'areas.id in (?) OR common_denominators_locations && \'{?}\'::int[]',
        company_user.area_ids,
        company_user.accessible_locations + [-1])
    end
  end

  def self.filters_scope(filters)
    areas = filters.user.company.areas.where('active in (?)', filters.items_to_show)
            .accessible_by_user(filters.user).order(:name).to_a
    filters.user.places.each do |p|
      areas.concat filters.user.company.areas
                   .where('active in (?)', filters.items_to_show || [true, false])
                   .where('id NOT IN (?)', areas.map(&:id) + [0]).select { |a| a.place_in_locations?(p) }
    end

    areas = areas.sort_by(&:name).map { |a| [a.id, a.name] }
  end

  serialize :common_denominators

  before_save :initialize_common_denominators

  attr_accessor :events_count

  searchable do
    integer :id

    text :name, stored: true

    string :name

    integer :location_ids, multiple: true do
      common_denominators_locations + locations.map(&:id)
    end

    string :status

    boolean :active

    integer :company_id
  end

  # Returns a list of locations ids that are associated to the area
  def locations
    Rails.cache.fetch("area_locations_#{id}") do
      Location.joins('INNER JOIN places ON places.location_id=locations.id')
              .where(places: { id: place_ids, is_location: true }).group('locations.id').to_a
    end
  end

  def cities
    places.order('places.name ASC').select { |p| p.types.present? && p.types.include?('locality') }
  end

  def count_events(_place, parents, count)
    self.events_count ||= 0
    return unless parents.join('/').include?((common_denominators || []).join('/'))
    self.events_count += count
  end

  # If place is in /North America/United States/California/Los Angeles and the area
  # includes Los Angeles or any parent (like California)
  def place_in_scope?(place)
    if place.present?
      @place_ids ||= place_ids
      return true if place.persisted? && @place_ids.include?(place.id)
      political_location = Place.political_division(place).join('/').downcase
      locations.any? { |location| political_location.include?(location.path) }
    else
      false
    end
  end

  # True for "North America/United States/Texas" in ["North America/United States/Texas/Austin", "North America/United States/Texas/Bee Cave"
  # False for "North America/United States/Chicago" in ["North America/United States/Texas/Austin", "North America/United States/Texas/Bee Cave"
  def place_in_locations?(place)
    if place.present?
      political_location = Place.political_division(place).join('/').downcase
      locations.any? { |location| location.path.include?(political_location) }
    else
      false
    end
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  class << self
    def searchable_params
      [area: [], status: []]
    end

    def update_common_denominators(area)
      area.send(:update_common_denominators)
      Rails.cache.delete("area_locations_#{area.id}")
      area.campaign_ids.each do |id|
        Rails.cache.delete("campaign_locations_#{id}")
        Rails.cache.delete("area_campaign_locations_#{area.id}_#{id}")
      end
    end
  end

  def self.report_fields
    {
      name: { title: 'Name' }
    }
  end

  def filter_subitems
    self.places.pluck('places.id, places.name, \'place\'')
  end

  protected

  # Generates the common denominators of the places within this area. Example:
  #  ['North America', 'United States', 'California', 'Los Angeles']
  # if all the places on the area are within Los Angeles
  def update_common_denominators
    denominators = []
    list_places = places.all.to_a.select { |p| !p.types.nil? && p.is_location? }
    continents = list_places.map(&:continent_name)
    if continents.compact.size == list_places.size && continents.uniq.size == 1
      denominators.push continents.first
      countries = list_places.map(&:country_name)
      if countries.compact.size == list_places.size && countries.uniq.size == 1
        denominators.push countries.first
        states = list_places.map(&:state_name)
        if states.compact.size == list_places.size && states.uniq.size == 1
          denominators.push states.first
          cities = list_places.map(&:city)
          if cities.compact.size == list_places.size && cities.uniq.size == 1
            denominators.push cities.first
          end
        end
      end
    end
    paths = denominators.count.times.map { |i| denominators.slice(0, i + 1).compact.join('/').downcase }
    common_locations = paths.map { |path| Location.find_or_create_by(path: path).id }
    update_attributes common_denominators: denominators, common_denominators_locations: common_locations
  end

  def initialize_common_denominators
    self.common_denominators ||= []
  end
end
