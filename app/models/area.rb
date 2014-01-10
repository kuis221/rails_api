# == Schema Information
#
# Table name: areas
#
#  id                  :integer          not null, primary key
#  name                :string(255)
#  description         :text
#  active              :boolean          default(TRUE)
#  company_id          :integer
#  created_by_id       :integer
#  updated_by_id       :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  common_denominators :text
#

class Area < ActiveRecord::Base
  include GoalableModel
  track_who_does_it

  scoped_to_company

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, presence: true

  has_many :placeables, as: :placeable, inverse_of: :placeable #, after_add: :update_common_denominators, after_remove: :update_common_denominators
  has_many :places, through: :placeables

  has_and_belongs_to_many :campaigns, :order => 'name ASC'

  scope :active, lambda{ where(active: true) }
  scope :not_in_venue, lambda{|place| where("areas.id not in (?)", place.area_ids + [0]) }

  serialize :common_denominators

  before_save :initialize_common_denominators

  attr_accessor :events_count

  searchable do
    integer :id

    text :name, stored: true

    string :name
    string :status

    boolean :active

    integer :company_id
  end


  def locations
    @locations ||= begin
      list_places = places.select{|p| !p.types.nil? && (p.types & ['sublocality', 'locality', 'administrative_area_level_1', 'administrative_area_level_2', 'administrative_area_level_3', 'country', 'natural_feature']).count > 0 }
      list_places.map{|place| [place.continent_name, place.country_name, place.state_name, place.city, (place.types.present? && place.types.include?('sublocality') ? place.name : nil)].compact.join('/') }.uniq
    end
  end

  def count_events(place, parents, count)
    self.events_count ||= 0
    if parents.join('/').include?((common_denominators || []).join('/'))
      self.events_count += count
    end
  end

  # If place is in /North America/United States/California/Los Angeles and the area
  # par
  def place_in_scope?(place)
    if place.present?
      political_location = Place.political_division(place).join('/')
      locations.any?{|location| political_location.include?(location) }
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
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search do
        with(:company_id, params[:company_id])
        with(:status, params[:status]) if params.has_key?(:status) and params[:status].present?
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'area'
            with :id, value
          end
        end

        if include_facets
          facet :status
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end

  protected

    # Generates the common denominators of the places within this area. Example:
    #  ['North America', 'United States', 'California', 'Los Angeles']
    # if all the places on the area are within Los Angeles
    def update_common_denominators
      denominators = []
      list_places = places.select{|p| !p.types.nil? && (p.types & ['sublocality', 'locality', 'administrative_area_level_1', 'administrative_area_level_2', 'administrative_area_level_3', 'country', 'natural_feature']).count > 0 }
      continents = list_places.map(&:continent_name)
      if continents.compact.size == list_places.size and continents.uniq.size == 1
        denominators.push continents.first
        countries = list_places.map(&:country_name)
        if countries.compact.size == list_places.size and countries.uniq.size == 1
          denominators.push countries.first
          states = list_places.map(&:state_name)
          if states.compact.size == list_places.size and states.uniq.size == 1
            denominators.push states.first
            cities = list_places.map(&:city)
            if cities.compact.size == list_places.size and cities.uniq.size == 1
              denominators.push cities.first
            end
          end
        end
      end
      update_attribute :common_denominators, denominators
    end

    def initialize_common_denominators
      self.common_denominators ||= []
    end
end
