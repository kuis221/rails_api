# == Schema Information
#
# Table name: venues
#
#  id                   :integer          not null, primary key
#  company_id           :integer
#  place_id             :integer
#  events_count         :integer
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
#  score_impressions    :integer
#  score_cost           :integer
#

require 'normdist'

class Venue < ActiveRecord::Base
  scoped_to_company

  belongs_to :place

  has_many :events, through: :place
  has_many :activities, -> { order('activity_date ASC') }, as: :activitable do
    def include_from_events
      events_activities = Activity.
        where(
          activitable_type: 'Event',
          events: {place_id: proxy_association.owner.place_id, company_id: proxy_association.owner.company_id}).
        joins('INNER JOIN events ON events.id=activities.activitable_id').active
      (all + events_activities).sort_by(&:activity_date)
    end
  end

  include Normdist

  delegate :name, :types, :formatted_address, :formatted_phone_number, :website, :price_level, :city, :street, :state, :state_name, :country, :country_name, :zipcode, :reference, :latitude, :longitude, :opening_hours, :td_linx_code, to: :place

  searchable do
    integer :place_id
    integer :company_id

    text :name, stored: true
    string :name
    text :types do
      begin
        place.types.join ' '
      rescue
        ''
      end
    end

    text :address do
      "#{street}, #{city}, #{state}, #{state_name}, #{country_name}"
    end

    string :types, multiple: true

    latlon(:location) { Sunspot::Util::Coordinates.new(latitude, longitude) }

    integer :locations, multiple: true do
      place.locations.pluck('locations.id') if place.present?
    end

    integer :campaign_ids, multiple: true
    string :status do
      'Active'
    end

    integer :events_count, :stored => true
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
    self.events_count = Event.where(company_id: company_id, place_id: place_id).active.count
    self.promo_hours = Event.where(company_id: company_id).active.total_promo_hours_for_places(place_id)

    results = EventData.scoped_by_place_id_and_company_id(place_id, company_id).for_active_events
    self.impressions = results.sum(:impressions).round
    self.interactions = results.sum(:interactions).round
    self.sampled = results.sum(:samples).round
    self.spent = results.sum(:spent).round

    self.avg_impressions = 0
    self.avg_impressions_hour = 0
    self.avg_impressions_cost = 0
    self.avg_impressions = self.impressions/self.events_count if self.events_count > 0
    self.avg_impressions_hour = self.impressions/self.promo_hours if self.promo_hours > 0
    self.avg_impressions_cost = self.spent/self.impressions if self.impressions > 0

    compute_scoring

    reindex_neighbors_venues =  avg_impressions_changed? || avg_impressions_cost_changed?

    save

    if reindex_neighbors_venues and neighbors_establishments_search
      neighbors_establishments_search.results.each do |venue|
        venue.compute_scoring.save if venue.id != self.id
      end
    end

    true

  end

  def compute_scoring
    # Calculates the scoring for the venue
    self.score = nil
    if neighbors_establishments_search && neighbors_establishments_search.respond_to?(:stat_response)
      unless neighbors_establishments_search.stat_response['stats_fields']["avg_impressions_hour_es"].nil?
        mean = neighbors_establishments_search.stat_response['stats_fields']["avg_impressions_hour_es"]['mean']
        stddev = neighbors_establishments_search.stat_response['stats_fields']["avg_impressions_hour_es"]['stddev']

        self.score_impressions = (normdist((avg_impressions_hour-mean)/stddev) * 100).round if stddev != 0.0

        mean = neighbors_establishments_search.stat_response['stats_fields']["avg_impressions_cost_es"]['mean']
        stddev = neighbors_establishments_search.stat_response['stats_fields']["avg_impressions_cost_es"]['stddev']

        self.score_cost = 100 - (normdist((avg_impressions_cost-mean)/stddev) * 100).round if stddev != 0.0

        if self.score_impressions && self.score_cost
          self.score = (self.score_impressions + self.score_cost) / 2
        end
      end
    end
    self
  end

  def neighbors_establishments_search
    @neighbors_establishments_search ||= begin
      types = types_without_establishment
      Venue.solr_search do
        with(:company_id, company_id)
        with(:location).in_radius(latitude, longitude, 5)
        with(:types, types) if types.any?
        with(:avg_impressions_hour).greater_than(0)

        stat(:avg_impressions_hour, :type => "stddev")
        stat(:avg_impressions_hour, :type => "mean")

        stat(:avg_impressions_cost, :type => "stddev")
        stat(:avg_impressions_cost, :type => "mean")
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
    if place.present? and place.types.is_a?(Array)
      place.types - ['establishment']
    else
      []
    end
  end

  def overall_graphs_data
    return @overall_graphs_data if @overall_graphs_data

    results_scope = FormFieldResult.for_place_in_company(place_id, company_id).where(events: {active: true})
    @overall_graphs_data = {}
    [:age, :gender, :ethnicity].each do |kpi|
      if Kpi.send(kpi).present?
        @overall_graphs_data[kpi] = Hash[Kpi.send(kpi).kpis_segments.map do |s|
          [s.text, results_scope.for_kpi(Kpi.send(kpi)).average("COALESCE(NULLIF(form_field_results.hash_value -> '#{s.id}', ''), '0')::NUMERIC") || 0]
        end]
      end
    end

    # First let the DB to do the math for the events that starts and ends the same day... (the easy part)
    tz = ActiveSupport::TimeZone.zones_map[Time.zone.name].tzinfo.identifier
    stats_by_day = Event.select("count(events.id) AS counting, sum(events.promo_hours) as promo_hours_sum, sum(event_data.impressions) as impressions_sum, sum(event_data.spent) as cost, EXTRACT(DOW FROM TIMEZONE('UTC', events.start_at) AT TIME ZONE '#{tz}') AS weekday").active
         .joins(:event_data)
         .group("EXTRACT(DOW FROM TIMEZONE('UTC', events.start_at) AT TIME ZONE '#{tz}')")
         .where(place_id: place_id, company_id: company_id)
         .where(["date_trunc('day', TIMEZONE('UTC', start_at) AT TIME ZONE ?) = date_trunc('day', TIMEZONE('UTC', end_at) AT TIME ZONE ?)", tz, tz])
    @overall_graphs_data[:impressions_promo] = Hash[(0..6).map{|i|[i, 0]}]
    @overall_graphs_data[:cost_impression] = Hash[(0..6).map{|i|[i, 0]}]
    event_counts = Hash[(0..6).map{|i|[i, 0]}]
    stats_by_day.each do |s|
      @overall_graphs_data[:impressions_promo][(s.weekday == '0' ? 6 : s.weekday.to_i-1)] = s.impressions_sum.to_f / s.promo_hours_sum.to_f if s.promo_hours_sum.to_f > 0
      @overall_graphs_data[:cost_impression][(s.weekday == '0' ? 6 : s.weekday.to_i-1)] = s.cost.to_f / s.impressions_sum.to_f if s.impressions_sum.to_f > 0
      event_counts[(s.weekday == '0' ? 6 : s.weekday.to_i-1)] = s.counting.to_i
    end

    # Then we handle the case when the events ends on a different day manually because coudn't think on a better way to do it
    events = Event.select('events.*, event_data.impressions, event_data.spent').where(place_id: place_id, company_id: company_id).active
         .joins(:event_data)
         .where(["date_trunc('day', TIMEZONE('UTC', start_at) AT TIME ZONE ?) <> date_trunc('day', TIMEZONE('UTC', end_at) AT TIME ZONE ?)", tz, tz])
    events.each do |e|
      (e.start_at.to_date..e.end_at.to_date).each do |day|
        wday = (day.wday == 0 ? 6 : day.wday-1)
        if e.promo_hours.to_i > 0
          hours = ([e.end_at, day.end_of_day].min - [e.start_at, day.beginning_of_day].max) / 3600
          @overall_graphs_data[:impressions_promo][wday] += (e.impressions.to_i/e.promo_hours * hours)
        end

        if e.impressions.to_i > 0
          @overall_graphs_data[:cost_impression][(day.wday == 0 ? 6 : day.wday-1)] += (e.spent.to_f/e.impressions.to_i)
        end

        event_counts[wday] += 1
      end
    end

    event_counts.each do |wday, counting|
      if counting > 0
        @overall_graphs_data[:impressions_promo][wday] = @overall_graphs_data[:impressions_promo][wday] / counting
        @overall_graphs_data[:cost_impression][wday] = @overall_graphs_data[:cost_impression][wday] / counting
      end
    end

    @overall_graphs_data
  end

  def self.do_search(params, include_facets=false)
    ss = solr_search(include: [:place]) do

      with(:company_id, params[:company_id]) if params.has_key?(:company_id) and params[:company_id].present?

      # Filter by user permissions
      company_user = params[:current_company_user]
      if company_user.present?
        unless company_user.role.is_admin?
          #with(:campaign_ids, company_user.accessible_campaign_ids + [0])
          any_of do
            locations = company_user.accessible_locations
            places_ids = company_user.accessible_places

            with(:place_id, places_ids + [0])
            with(:locations, locations + [0])
          end
        end
      end

      if params[:location].present?
        radius = params.has_key?(:radius) ? params[:radius] : 50
        (lat, lng) = params[:location].split(',')
        with(:location).in_radius(lat, lng, radius)
      end

      if params[:q].present?
        fulltext params[:q] do
          fields(:types, :name => 5.0)
          phrase_fields :name => 5.0
          fields(:address => 2.0) if params[:search_address]
        end
      end

      if params.has_key?(:campaign) and params[:campaign].present?
        locations = places = []
        Campaign.where(company_id: params[:company_id], id: params[:campaign]).each do |c|
          locations += c.accessible_locations
          places += c.place_ids
        end
        any_of do
          with(:campaign_ids, params[:campaign])
          with(:locations, locations.uniq.compact) if locations.any?
          with(:place_id, places.uniq.compact) if places.any?
        end
      end

      if params.has_key?(:brand) and params[:brand].present?
        with :campaign_ids, Campaign.select('DISTINCT(campaigns.id)').joins(:brands).where(brands: {id: params[:brand]}).map(&:id)
      end

      with(:locations, params[:locations]) if params.has_key?(:locations) and params[:locations].present?

      with(:locations, Area.where(id: params[:area]).map{|a| a.locations.map(&:id) }.flatten + [0]  ) if params[:area].present?

      [:events_count, :promo_hours, :impressions, :interactions, :sampled, :spent, :venue_score].each do |param|
        if params[param].present? && params[param][:min].present? && params[param][:max].present?
          with(param, params[param][:min].to_i..params[param][:max].to_i)
        elsif params[param].present? && params[param][:min].present?
          with(param).greater_than_or_equal_to(params[param][:min])
        end
      end

      stat(:events_count, :type => "max")
      stat(:promo_hours, :type => "max")
      stat(:impressions, :type => "max")
      stat(:interactions, :type => "max")
      stat(:sampled, :type => "max")
      stat(:spent, :type => "max")
      stat(:venue_score, :type => "max")

      if include_facets
        facet :place_id
        facet :campaign_ids
      end

      order_by(params[:sorting] || :venue_score, params[:sorting_dir] || :desc)
      paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)

    end
  end

  def campaign_ids
    @campaign_ids ||= Campaign.joins(:events)
        .where(events: {place_id: place_id}, company_id: company_id)
        .pluck('DISTINCT(events.campaign_id)')
  end
end
