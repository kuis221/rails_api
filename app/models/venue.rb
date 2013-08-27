# == Schema Information
#
# Table name: venues
#
#  id                   :integer          not null, primary key
#  company_id           :integer
#  place_id             :integer
#  events               :integer
#  promo_hours          :decimal(8, 2)    default(0.0)
#  impressions          :integer
#  interactions         :integer
#  sampled              :integer
#  spent                :decimal(10, 2)   default(0.0)
#  score                :integer
#  avg_impressions      :decimal(8, 2)    default(0.0)
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  avg_impressions_hour :decimal(6, 2)    default(0.0)
#  avg_impressions_cost :decimal(8, 2)    default(0.0)
#

require 'normdist'

class Venue < ActiveRecord::Base
  belongs_to :company
  belongs_to :place

  include Normdist

  attr_accessible :place_id, :company_id

  delegate :name, :types, :formatted_address, :formatted_phone_number, :website, :price_level, :city, :street, :state, :zipcode, :reference, :latitude, :longitude, :opening_hours, to: :place

  searchable do
    integer :place_id
    integer :company_id

    text :name
    text :types do
      begin
        place.types.join ' '
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
    double :avg_impressions_hour, :stored => true
    double :avg_impressions_cost, :stored => true

    integer :venue_score, :stored => true do
      score
    end
  end


  def compute_stats
    self.events = Event.where(company_id: company_id, place_id: place_id).count
    self.promo_hours = Event.where(company_id: company_id).total_promo_hours_for_places(place_id)

    results = EventData.scoped_by_place_id_and_company_id(place_id, company_id)
    self.impressions = results.sum(:impressions).round
    self.interactions = results.sum(:interactions).round
    self.sampled = results.sum(:samples).round
    self.spent = results.sum(:cost).round

    self.avg_impressions = 0
    self.avg_impressions_hour = 0
    self.avg_impressions_cost = 0
    self.avg_impressions = self.impressions/self.events if self.events > 0
    self.avg_impressions_hour = self.impressions/self.promo_hours if self.promo_hours > 0
    self.avg_impressions_cost = self.spent/self.impressions if self.impressions > 0

    compute_scoring

    reindex_neighbors_venues =  avg_impressions_changed?

    save

    if reindex_neighbors_venues and neighbors_establishments_search
      neighbors_establishments_search.results.each do |venue|
        venue.compute_scoring.save if venue.id != self.id
      end
    end

  end

  def compute_scoring
    # Calculates the scoring for the venue
    self.score = nil
    if neighbors_establishments_search
      unless neighbors_establishments_search.stat_response['stats_fields']["avg_impressions_hour_es"].nil?
        mean = neighbors_establishments_search.stat_response['stats_fields']["avg_impressions_hour_es"]['mean']
        stddev = neighbors_establishments_search.stat_response['stats_fields']["avg_impressions_hour_es"]['stddev']

        self.score = (normdist((avg_impressions-mean)/stddev) * 100).to_i if stddev != 0.0
      end
    end
    self
  end

  def neighbors_establishments_search
    @neighbors_establishments_search ||= begin
      types = types_without_establishment
      if types.count > 0
        Venue.solr_search do
          with(:company_id, company_id)
          with(:location).in_radius(latitude, longitude, 5)
          with(:types, types_without_establishment )
          with(:avg_impressions_hour).greater_than(0)

          stat(:avg_impressions_hour, :type => "stddev")
          stat(:avg_impressions_hour, :type => "mean")
        end
      else
        false
      end
    end
  end

  def photos
    place.photos(company_id)
  end

  def reviews
    place.reviews(company_id)
  end

  def types_without_establishment
    if place.types.is_a?(Array)
      place.types - ['establishment']
    else
      []
    end
  end

  def overall_graphs_data
    return @overall_graphs_data if @overall_graphs_data

    results_scope = EventResult.scoped_by_place_id_and_company_id(place_id, company_id)
    @overall_graphs_data = {}
    [:age, :gender, :ethnicity].each do |kpi|
      results = results_scope.send(kpi).select('event_results.kpis_segment_id, sum(event_results.scalar_value) AS segment_sum, avg(event_results.scalar_value) AS segment_avg').group('event_results.kpis_segment_id')
      segments = Kpi.send(kpi).kpis_segments
      @overall_graphs_data[kpi] = Hash[segments.map{|s| [s.text, results.detect{|r| r.kpis_segment_id == s.id}.try(:segment_avg).try(:to_f) || 0]}]
    end

    # First let the DB to do the math for the events that starts and ends the same day... (the easy part)
    tz = Time.zone.now.strftime('%Z')
    stats_by_day = Event.select("count(events.id) AS counting, sum(events.promo_hours) as promo_hours, sum(event_data.impressions) as impressions, EXTRACT(DOW FROM events.start_at AT TIME ZONE '#{tz}') AS weekday")
         .joins(:event_data)
         .group("EXTRACT(DOW FROM events.start_at AT TIME ZONE '#{tz}')")
         .where(place_id: place_id, company_id: company_id)
         .where(["date_trunc('day',start_at AT TIME ZONE ?) = date_trunc('day',end_at AT TIME ZONE ?)", tz, tz])
    @overall_graphs_data[:trends_week_day] = Hash[(0..6).map{|i|[i, 0]}]
    stats_by_day.each{|s| @overall_graphs_data[:trends_week_day][(s.weekday == '0' ? 6 : s.weekday.to_i-1)] = s.impressions.to_f / s.promo_hours.to_f }

    # Then we handle the case when the events ends on a different day manually because coudn't think on a better way to do it
    events = Event.select('events.*, event_data.impressions').where(place_id: place_id, company_id: company_id)
         .joins(:event_data)
         .where(["date_trunc('day',start_at AT TIME ZONE ?) <> date_trunc('day',end_at AT TIME ZONE ?)", tz, tz])
         .where('events.promo_hours > 0')
    events.each do |e|
      (e.start_at.to_date..e.end_at.to_date).each do |day|
        hours = ([e.end_at, day.end_of_day].min - [e.start_at, day.beginning_of_day].max) / 3600
        @overall_graphs_data[:trends_week_day][(day.wday == 0 ? 6 : day.wday-1)] += (e.impressions.to_i/e.promo_hours * hours)
      end
    end

    @overall_graphs_data
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

      [:events, :promo_hours, :impressions, :interactions, :samples, :spent, :venue_score].each do |param|
        if params[param].present? && params[param][:min].present? && params[param][:max].present?
          with(param.to_sym, params[param][:min].to_i..params[param][:max].to_i)
        elsif params[param].present? && params[param][:min].present?
          with(param.to_sym).greater_than_or_equal_to(params[param][:min])
        end
      end

      stat(:events, :type => "max")
      stat(:promo_hours, :type => "max")
      stat(:impressions, :type => "max")
      stat(:interactions, :type => "max")
      stat(:sampled, :type => "max")
      stat(:spent, :type => "max")
      stat(:venue_score, :type => "max")

      if include_facets
        facet :place
        facet :campaigns
      end

      order_by(params[:sorting] || :venue_score, params[:sorting_dir] || :desc)
      paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
    end
  end


  private
    def campaigns
      @campaigns ||= Campaign.select('DISTINCT campaigns.id, campaigns.name').joins(:events).where(events: {place_id: place_id}, company_id: company_id)
    end
end
