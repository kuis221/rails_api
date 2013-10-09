# == Schema Information
#
# Table name: areas
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  active        :boolean          default(TRUE)
#  company_id    :integer
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Area < ActiveRecord::Base
  include GoalableModel
  track_who_does_it

  scoped_to_company

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, presence: true

  has_many :placeables, as: :placeable
  has_many :places, through: :placeables

  scope :active, lambda{ where(active: true) }
  scope :not_in_venue, lambda{|place| where("areas.id not in (?)", place.area_ids + [0]) }

  attr_accessor :events_count

  searchable do
    integer :id

    text :name, stored: true

    string :name
    string :status

    boolean :active

    integer :company_id
  end

  # Returns an array of the common denominators of the places within this area. Example:
  #  ['North America', 'United States', 'California', 'Los Angeles']
  def common_denominators(include_establishments=false)
    denominators = []
    if include_establishments
      list_places = places.all
    else
      list_places = places.select{|p| !p.types.nil? && (p.types & ['locality', 'administrative_area_level_1', 'administrative_area_level_2', 'administrative_area_level_3', 'country', 'natural_feature']).count > 0 }
    end
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
    denominators
  end

  def count_events(place, parents, count)
    self.events_count ||= 0
    if places.include?(place)
      self.events_count += count
    elsif parents.join('/').include?(common_denominators.join('/'))
      self.events_count += count
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
end
