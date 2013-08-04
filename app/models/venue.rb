# == Schema Information
#
# Table name: venues
#
#  id              :integer          not null, primary key
#  company_id      :integer
#  place_id        :integer
#  events          :integer
#  promo_hours     :decimal(8, 2)    default(0.0)
#  impressions     :integer
#  interactions    :integer
#  sampled         :integer
#  spent           :decimal(10, 2)   default(0.0)
#  score           :integer
#  avg_impressions :decimal(8, 2)    default(0.0)
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

require 'normdist'

class Venue < ActiveRecord::Base
  belongs_to :company
  belongs_to :place

  include Normdist

  attr_accessible :place_id, :company_id

  delegate :name, :types, :formatted_address, :formatted_phone_number, :website, :price_level, :city, :street, :state, :zipcode, :reference, :latitude, :longitude, to: :place

  searchable do
    integer :place_id
    integer :company_id

    text :name
    text :types do
      begin
        types = place.types
        types.map do |type|
          if PLACE_TYPES_SYMS.has_key?(type)
            PLACE_TYPES_SYMS[type]
          else
            [type]
          end
        end.flatten.join ' '
      rescue
        ''
      end
    end

    string :types, multiple: true

    latlon(:location) { Sunspot::Util::Coordinates.new(latitude, longitude) }

    string :locations, multiple: true do
      Place.locations_for_index(place)
    end

    string :place do
      Place.location_for_index(place)
    end

    string :campaigns, multiple: true do
      campaigns.map{|c| c.id.to_s + '||' + c.name.to_s}
    end

    integer :campaign_ids, multiple: true do
      campaigns.map(&:id)
    end

    integer :events, :stored => true
    double :promo_hours, :stored => true
    integer :impressions, :stored => true
    integer :interactions, :stored => true
    integer :sampled, :stored => true
    double :spent, :stored => true
    double :avg_impressions, :stored => true
  end


  def compute_stats
    self.events = Event.where(company_id: company_id, place_id: place_id).count
    self.promo_hours = Event.where(company_id: company_id).total_promo_hours_for_places(place_id)

    results = EventResult.scoped_by_place_id_and_company_id(place_id, company_id)
    self.impressions = results.impressions.sum(:scalar_value).round
    self.interactions = results.consumers_interactions.sum(:scalar_value).round
    self.sampled = results.consumers_sampled.sum(:scalar_value).round
    self.spent = results.spent.sum(:scalar_value).round

    self.avg_impressions = 0
    self.avg_impressions = self.impressions/self.events if self.events > 0

    compute_score

    save
  end

  def compute_score
    search = Venue.solr_search do
      with(:company_id, company_id)
      with(:location).in_radius(latitude, longitude, 5)
      with(:avg_impressions).greater_than(0)

      stat(:avg_impressions, :type => "stddev")
      stat(:avg_impressions, :type => "mean")
    end
    self.score = nil
    unless search.stat_response['stats_fields']["avg_impressions_es"].nil?
      mean = search.stat_response['stats_fields']["avg_impressions_es"]['mean']
      stddev = search.stat_response['stats_fields']["avg_impressions_es"]['stddev']

      self.score = (normdist((avg_impressions-mean)/stddev) * 100).to_i if stddev != 0.0
    end
  end

  def photos
    place.photos(company_id)
  end

  def reviews
    place.reviews(company_id)
  end


  def self.do_search(params, include_facets=false)
    ss = solr_search do

      with(:company_id, params[:company_id]) if params.has_key?(:company_id) and params[:company_id].present?

      if params[:location].present?
        radius = params.has_key?(:radius) ? params[:radius] : 50
        (lat, lng) = params[:location].split(',')
        with(:location).in_radius(lat, lng, radius)
      end

      if params[:q].present?
        fulltext params[:q] do
          fields(:name)
          fields(:types)
        end
      end

      with(:campaign_ids, params[:campaign]) if params.has_key?(:campaign) and params[:campaign].present?

      if params.has_key?(:brand) and params[:brand].present?
        with :campaign_ids, Campaign.select('DISTINCT(campaigns.id)').joins(:brands).where(brands: {id: params[:brand]}).map(&:id)
      end

      if params.has_key?(:place) and params[:place].present?
        place_paths = []
        params[:place].each do |place|
          # The location comes BASE64 encoded as a pair "id||name"
          # The ID is a md5 encoded string that is indexed on Solr
          (id, name) = Base64.decode64(place).split('||')
          place_paths.push id
        end
        if place_paths.size > 0
          with(:locations, place_paths)
        end
      end

      [:events, :promo_hours, :impressions, :interactions, :samples, :spent].each do |param|
        if params[param].present? && params[param][:min].present? && params[param][:max].present?
          with(param.to_sym, params[param][:min].to_i..params[param][:max].to_i)
        elsif params[param].present? && params[param][:min].present?
          with(param.to_sym).greater_than(params[param][:min])
        end
      end

      stat(:events, :type => "max")
      stat(:promo_hours, :type => "max")
      stat(:impressions, :type => "max")
      stat(:interactions, :type => "max")
      stat(:sampled, :type => "max")
      stat(:spent, :type => "max")

      if include_facets
        facet :place
        facet :campaigns
      end

      paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
    end
  end


  private
    def campaigns
      @campaigns ||= Campaign.select('DISTINCT campaigns.id, campaigns.name').joins(:events).where(events: {place_id: place_id}, company_id: company_id)
    end
end
