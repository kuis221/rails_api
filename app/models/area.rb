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
  track_who_does_it

  scoped_to_company

  attr_accessible :name, :description

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, presence: true

  # Areas-Places relationship
  has_and_belongs_to_many :places

  searchable do
    integer :id

    text :name, stored: true
    text :description

    string :name
    string :description
    string :status

    boolean :active

    integer :company_id
  end

  # Returns an array of the common denominators of the places within this area. Example:
  #  ['North America', 'United States', 'California', 'Los Angeles']
  def common_denominators
    denominators = []
    continents = places.map(&:continent_name)
    if continents.compact.size == places.size and continents.uniq.size == 1
      denominators.push continents.first
      countries = places.map(&:country_name)
      if countries.compact.size == places.size and countries.uniq.size == 1
        denominators.push countries.first
        states = places.map(&:state_name)
        if states.compact.size == places.size and states.uniq.size == 1
          denominators.push states.first
          cities = places.map(&:city)
          if cities.compact.size == places.size and cities.uniq.size == 1
            denominators.push cities.first
          end
        end
      end
    end
    denominators
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
