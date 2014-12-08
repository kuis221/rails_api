# == Schema Information
#
# Table name: events
#
#  id             :integer          not null, primary key
#  campaign_id    :integer
#  company_id     :integer
#  start_at       :datetime
#  end_at         :datetime
#  aasm_state     :string(255)
#  created_by_id  :integer
#  updated_by_id  :integer
#  created_at     :datetime         not null
#  updated_at     :datetime         not null
#  active         :boolean          default(TRUE)
#  place_id       :integer
#  promo_hours    :decimal(6, 2)    default(0.0)
#  reject_reason  :text
#  timezone       :string(255)
#  local_start_at :datetime
#  local_end_at   :datetime
#  description    :text
#

class Event < ActiveRecord::Base
  include AASM

  track_who_does_it

  attr_accessor :visit_id

  belongs_to :campaign
  belongs_to :place, autosave: true

  has_many :tasks, -> { order 'due_at ASC' }, dependent: :destroy, inverse_of: :event
  has_many :photos, -> { order('created_at DESC').where(asset_type: 'photo') },
           class_name: 'AttachedAsset', dependent: :destroy, as: :attachable, inverse_of: :attachable
  has_many :active_photos, -> { order('created_at DESC').where(asset_type: 'photo', active: true) },
           class_name: 'AttachedAsset', as: :attachable, inverse_of: :attachable
  has_many :documents, -> { order('created_at DESC').where(asset_type: 'document') },
           class_name: 'AttachedAsset', dependent: :destroy, as: :attachable, inverse_of: :attachable
  has_many :teamings, as: :teamable, dependent: :destroy, inverse_of: :teamable
  has_many :teams, through: :teamings, after_remove: :after_remove_member
  has_many :results, as: :resultable, dependent: :destroy,
                     class_name: 'FormFieldResult', inverse_of: :resultable do
    def active
      where(form_field_id: proxy_association.owner.campaign.form_field_ids)
    end
  end
  has_many :event_expenses, dependent: :destroy, inverse_of: :event, autosave: true
  has_many :activities, -> { order('activity_date ASC') }, as: :activitable, dependent: :destroy do
    def active
      joins(activity_type: :activity_type_campaigns)
        .where(active: true, activity_type_campaigns: { campaign_id: proxy_association.owner.campaign_id })
    end
  end
  has_one :event_data, autosave: true, dependent: :destroy

  has_many :comments, -> { order 'comments.created_at ASC' }, dependent: :destroy, as: :commentable,  inverse_of: :commentable

  has_many :surveys, -> { order 'surveys.created_at ASC' }, dependent: :destroy,  inverse_of: :event

  # Events-Users relationship
  has_many :memberships, dependent: :destroy, as: :memberable, inverse_of: :memberable
  has_many :users, class_name: 'CompanyUser', source: :company_user, through: :memberships,
                   after_remove: :after_remove_member

  has_many :contact_events, dependent: :destroy

  accepts_nested_attributes_for :surveys
  accepts_nested_attributes_for :results
  accepts_nested_attributes_for :photos
  accepts_nested_attributes_for :comments, reject_if: proc { |attributes| attributes['content'].blank? }

  scoped_to_company

  scope :upcomming, -> { where('start_at >= ?', Time.zone.now) }
  scope :active, -> { where(active: true) }

  scope :by_campaigns, ->(campaigns) { where(campaign_id: campaigns) }
  scope :in_past, -> { where('events.end_at < ?', Time.now) }
  scope :with_team, ->(team) { joins(:teamings).where(teamings: { team_id: team }) }

  def self.between_dates(start_date, end_date)
    prefix = ''
    if Company.current.present? && Company.current.timezone_support?
      prefix = 'local_'
      start_date = start_date.strftime('%Y-%m-%d %H:%M:%S')
      end_date = end_date.strftime('%Y-%m-%d %H:%M:%S')
    end
    where("#{prefix}end_at > ? AND #{prefix}start_at < ?", start_date, end_date)
  end

  def self.with_user_in_team(user)
    joins('LEFT JOIN teamings ON teamings.teamable_id=events.id AND teamable_type=\'Event\'')
      .joins('LEFT JOIN memberships ON (memberships.memberable_id=events.id AND memberable_type=\'Event\') OR '\
                                      '(memberships.memberable_id=teamings.team_id AND memberable_type=\'Team\')')
      .where('memberships.company_user_id in (?)', user)
  end

  def self.for_campaigns_accessible_by(company_user)
    if company_user.is_admin?
      where(company_id: company_user.company_id)
    else
      where(company_id: company_user.company_id, campaign_id: company_user.accessible_campaign_ids + [0])
    end
  end

  def self.accessible_by_user(company_user)
    if company_user.is_admin?
      where(company_id: company_user.company_id)
    else
      where(company_id: company_user.company_id).for_campaigns_accessible_by(company_user).in_user_accessible_locations(company_user)
    end
  end

  def self.in_user_accessible_locations(company_user)
    if  company_user.is_admin?
      self
    else
      joins(:place)
        .where('events.place_id in (?) OR events.place_id in (
                select place_id FROM locations_places where location_id in (?))',
               company_user.accessible_places + [0],
               company_user.accessible_locations + [0]
        )
    end
  end

  def self.joins_for_user_teams
    joins('LEFT JOIN teamings ON teamings.teamable_id=events.id AND teamable_type=\'Event\'')
      .joins('LEFT JOIN teams ON teams.id=teamings.team_id')
      .joins('LEFT JOIN memberships ON
                (memberships.memberable_id=events.id AND memberable_type=\'Event\') OR
                (memberships.memberable_id=teams.id AND memberable_type=\'Team\')')
      .joins('LEFT JOIN company_users ON company_users.id=memberships.company_user_id')
      .joins('LEFT JOIN users ON users.id=company_users.user_id')
  end

  # Returns the events that are inside the campaigns scope, considering the
  # custom exclusions
  def self.in_campaign_area(area_campaign)
    has_exclusions = area_campaign.exclusions.any?
    has_inclusions = area_campaign.inclusions.any?
    subquery =
      Place.select('DISTINCT places.location_id')
      .joins(:placeables)
      .where(
          is_location: true,
          placeables: { placeable_type: 'Area', placeable_id: area_campaign.area_id })
    subquery = subquery.where.not(placeables: { place_id: area_campaign.exclusions }) if has_exclusions
    subquery = subquery.to_sql

    if has_inclusions
      subquery += " UNION " + Place.select('DISTINCT places.location_id')
                              .where(is_location: true, id: area_campaign.inclusions).to_sql
    end

    place_query =
      "SELECT place_id FROM locations_places
       INNER JOIN (#{subquery}) locations on locations.location_id=locations_places.location_id" +
      (has_exclusions ? " WHERE place_id not in (#{area_campaign.exclusions.join(',')})" : '')
    area_query =
      Placeable.select('place_id')
      .where(placeable_type: 'Area', placeable_id: area_campaign.area_id)
    area_query = area_query.where.not(place_id: area_campaign.exclusions) if has_exclusions
    joins(:place)
      .joins("INNER JOIN (#{area_query.to_sql} UNION #{place_query}) areas_places ON events.place_id=areas_places.place_id")
  end

  # Similar to in_campaign_area, except that this accepts severals areas and filter
  # the events based on given areas scope validating the custom exclusions for that area in that campaign
  def self.in_campaign_areas(campaign, areas)
    subquery =
      Place.select('DISTINCT places.location_id, areas_campaigns.area_id')
      .joins(:placeables)
      .where(placeables: { placeable_type: 'Area', placeable_id: areas }, is_location: true)
      .joins('INNER JOIN areas_campaigns
                ON areas_campaigns.campaign_id=' + campaign.id.to_s + ' AND
                areas_campaigns.area_id=placeables.placeable_id')
      .where('NOT (places.id = ANY (areas_campaigns.exclusions))').to_sql

    subquery += ' UNION ' +
      Place.select('DISTINCT places.location_id, areas_campaigns.area_id')
      .joins('INNER JOIN areas_campaigns ON places.id = ANY (areas_campaigns.inclusions)')
      .where(is_location: true, areas_campaigns: { area_id: areas, campaign_id: campaign.id }).to_sql

    place_query = "select place_id, locations.area_id FROM locations_places INNER JOIN (#{subquery})"\
                  ' locations ON locations.location_id=locations_places.location_id'
    area_query = Placeable.select('place_id, placeable_id area_id').where(placeable_type: 'Area', placeable_id: areas)
                 .joins("INNER JOIN areas_campaigns ON areas_campaigns.campaign_id=#{campaign.id} "\
                        'AND areas_campaigns.area_id=placeables.placeable_id')
                 .where('NOT (place_id = ANY (areas_campaigns.exclusions))').to_sql
    joins(:place)
      .joins("INNER JOIN (#{area_query} UNION #{place_query}) areas_places ON events.place_id=areas_places.place_id")
  end

  #
  def self.in_areas(areas)
    subquery = Place.select('DISTINCT places.location_id, placeables.placeable_id area_id')
               .joins(:placeables).where(placeables: { placeable_type: 'Area', placeable_id: areas }, is_location: true)
    place_query = "select place_id, locations.area_id FROM locations_places INNER JOIN (#{subquery.to_sql})"\
                  ' locations on locations.location_id=locations_places.location_id'
    area_query = Placeable.select('place_id, placeable_id area_id')
                 .where(placeable_type: 'Area', placeable_id: areas).to_sql
    joins(:place)
      .joins("INNER JOIN (#{area_query} UNION #{place_query}) areas_places ON events.place_id=areas_places.place_id")
  end

  def self.in_places(places)
    joins(:place).where(
      'events.place_id in (?) or events.place_id in (
          select place_id FROM locations_places where location_id in (?)
      )',
      places.map(&:id).uniq + [0],
      places.select(&:is_location?).map(&:location_id).compact.uniq + [0])
  end

  # validates_attachment_content_type :file, content_type: ['image/jpeg', 'image/png']
  validates :campaign_id, presence: true, numericality: true
  validate :valid_campaign?
  validates :company_id, presence: true, numericality: true
  validates :start_at, presence: true
  validates :end_at, presence: true, date: { on_or_after: :start_at, message: 'must be after' }
  validate :between_visit_date_range, before: [:create, :update], if: :visit_id

  DATE_FORMAT = %r{\A[0-1]?[0-9]/[0-3]?[0-9]/[0-2]0[0-9][0-9]\z}
  validates :start_date, format: { with: DATE_FORMAT, message: 'MM/DD/YYYY' }
  validates :end_date, format: { with: DATE_FORMAT, message: 'MM/DD/YYYY' }

  validate :event_place_valid?

  attr_accessor :start_date, :start_time, :end_date, :end_time

  after_initialize :set_start_end_dates
  before_validation :parse_start_end
  after_validation :delegate_errors

  after_validation :set_event_timezone

  before_save :set_promo_hours, :check_results_changed
  after_save :generate_event_data_record
  after_update :update_activities
  after_commit :reindex_associated
  after_commit :index_venue
  after_commit :create_notifications

  delegate :name, to: :campaign, prefix: true, allow_nil: true
  delegate :name, :state, :city, :zipcode, :neighborhood, :street_number, :route, :latitude,
           :state_name, :longitude, :formatted_address, :name_with_location, :td_linx_code,
           to: :place, prefix: true, allow_nil: true

  delegate :impressions, :interactions, :samples, :spent, :gender_female, :gender_male,
           :ethnicity_asian, :ethnicity_black, :ethnicity_hispanic, :ethnicity_native_american,
           :ethnicity_white, to: :event_data, allow_nil: true

  aasm do
    state :unsent, initial: true
    state :submitted
    state :approved
    state :rejected

    event :submit do
      transitions from: [:unsent, :rejected], to: :submitted, guard: :valid_results?
    end

    event :approve do
      transitions from: :submitted, to: :approved
    end

    event :reject do
      transitions from: :submitted, to: :rejected
    end
  end

  searchable do
    boolean :active
    time :start_at, stored: true, trie: true
    time :end_at, stored: true, trie: true

    # These two fields are used for when the timezone_support flag is "ON" for the current company
    time :local_start_at, stored: true, trie: true do
      timezone.present? ? Timeliness.parse(start_at.in_time_zone(timezone).strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC') : start_at
    end
    time :local_end_at, stored: true, trie: true do
      timezone.present? ? Timeliness.parse(end_at.in_time_zone(timezone).strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC') : end_at
    end

    string :status, multiple: true do
      [status, event_status]
    end
    string :start_time

    integer :id, stored: true
    integer :company_id
    integer :campaign_id, stored: true
    integer :place_id
    integer :user_ids, multiple: true
    integer :team_ids, multiple: true

    integer :location, multiple: true do
      locations_for_index
    end

    boolean :has_event_data do
      event_data?
    end

    boolean :has_comments do
      comments.count > 0
    end

    boolean :has_surveys do
      surveys.count > 0
    end

    double :promo_hours, stored: true
    double :impressions, stored: true
    double :interactions, stored: true
    double :samples, stored: true
    double :spent, stored: true
    double :gender_female, stored: true
    double :gender_male, stored: true
    double :ethnicity_asian, stored: true
    double :ethnicity_black, stored: true
    double :ethnicity_hispanic, stored: true
    double :ethnicity_native_american, stored: true
    double :ethnicity_white, stored: true
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def form_field_results
    campaign.form_fields.map do |field|
      result = results.find { |r| r.form_field_id == field.id } || results.build(form_field_id: field.id)
      result.form_field = field
      result
    end
  end

  def place_reference=(value)
    @place_reference = value
    return unless value && value.present?
    if value =~ /^[0-9]+$/
      self.place = Place.find(value)
    else
      reference, place_id = value.split('||')
      self.place = Place.load_by_place_id(place_id,  reference)
    end
  end

  def place_reference
    if place_id.present?
      place_id
    else
      "#{place.reference}||#{place.place_id}" if place.present?
    end
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  def event_status
    aasm_state.capitalize
  end

  def in_past?
    end_at < Time.now
  end

  def in_future?
    start_at > Time.now
  end

  def late?
    end_at.to_date <= (2.days.ago).to_date
  end

  def happens_today?
    start_at.to_date <= Time.zone.now.to_date && end_at.to_date >= Time.zone.now.to_date
  end

  def was_yesterday?
    end_at.to_date == (Time.zone.now.to_date - 1)
  end

  def event_data?
    campaign_id.present? &&
      (
        results.active.where(
          '(form_field_results.value is not null AND form_field_results.value <> \'\') OR
           (form_field_results.hash_value is not null AND btrim(array_to_string(avals(form_field_results.hash_value), \'\'))<>\'\')').count > 0
      )
  end

  def venue
    return if place_id.nil?
    @venue ||= Venue.find_or_create_by(company_id: company_id, place_id: place_id)
    @venue.place = place if association(:place).loaded?
    @venue
  end

  def contacts
    @contacts ||= contact_events.map(&:contactable).sort { |a, b| a.full_name <=> b.full_name }
  end

  def user_in_team?(user)
    ::Event.with_user_in_team(user).where(id: id).count > 0
  end

  def all_users
    users = []
    users += self.users if self.users.present?
    teams.each do |team|
      users += team.users if team.users.present?
    end
    users.uniq
  end

  def results_for(fields)
    # The results are mapped by field or kpi_id to make it find them in case the form field was deleted and readded to the form
    fields.map do |field|
      result = results.find { |r| r.form_field_id == field.id } || results.build(form_field_id: field.id)
      result.form_field = field # Assign it so it won't be reloaded if requested.
      result
    end
  end

  def result_for_kpi(kpi)
    field = campaign.form_fields.find { |f| f.kpi_id == kpi.id }
    return unless field.present?
    field.kpi = kpi # Assign it so it won't be reloaded if requested.
    results_for([field]).first
  end

  def results_for_kpis(kpis)
    kpis.map { |kpi| result_for_kpi(kpi) }.flatten.compact
  end

  def locations_for_index
    place.location_ids if place.present?
  end

  def kpi_goals
    @goals ||= Hash.new.tap do |h|
      total_campaign_events = campaign.events.count
      if total_campaign_events > 0
        campaign.goals.base.each do |goal|
          if goal.kpis_segment_id.present?
            h[goal.kpi_id] ||= {}
            h[goal.kpi_id][goal.kpis_segment_id] = goal.value unless goal.value.nil?
          else
            h[goal.kpi_id] = goal.value / total_campaign_events unless goal.value.nil?
          end
        end
      end
    end
  end

  def demographics_graph_data
    @demographics_graph_data ||= Hash.new.tap do |data|
      [:age, :gender, :ethnicity].each do |kpi_name|
        kpi =  Kpi.send(kpi_name)
        result = result_for_kpi(kpi)
        data[kpi_name] = Hash[kpi.kpis_segments.map { |s| [s.text, result.value[s.id.to_s].try(:to_f) || 0] }] if result.present?
      end
    end
  end

  def survey_statistics
    @survey_statistics ||= Hash.new.tap do |stats|
      stats[:total] = 0
      brands_map = Hash[campaign.survey_brands.map { |b| [b.id, b.name] }]
      surveys.each do|survey|
        stats[:total] += 1
        survey.surveys_answers.each do |answer|
          m = brands_map[answer.brand_id]
          if  answer.brand_id.present? && brands_map.key?(answer.brand_id)
            type = "question_#{answer.question_id}"
            stats[type] ||= {}
            if answer.question_id == 2
              if answer.answer.present? && answer.answer =~ /^[0-9]+(\.[0-9])?$/
                stats[type][m] ||= { count: 0, total: 0, avg: 0 }
                stats[type][m][:count] += 1
                stats[type][m][:total] += answer.answer.to_f
                stats[type][m][:avg] = stats[type][m][:total] / stats[type][m][:count]
              end
            else
              stats[type][answer.answer] ||= {}
              stats[type][answer.answer][m] ||= { count: 0, avg: 0.0 }
              stats[type][answer.answer][m][:count] += 1
              stats[type].each { |_a, brands| brands.each { |_b, s| s[:avg] = s[:count] * 100.0 / stats[:total] } }
            end
          elsif answer.kpi_id.present?
            type = "kpi_#{answer.kpi_id}"
            stats[type] ||= {}
            stats[type][answer.answer] ||= { count: 0, avg: 0 }
            stats[type][answer.answer][:count] += 1
            stats[type].each { |_a, s| s[:avg] = s[:count] * 100 / stats[:total] }
          end
        end
      end
    end
  end

  # Returns true if all the results for the current campaign are valid
  def valid_results?
    # Ensure all the results have been assigned/initialized
    results_for(campaign.form_fields).all?(&:valid?) if campaign.present?
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets = false)
      timezone = Time.zone.name
      timezone = 'UTC' if Company.current && Company.current.timezone_support?
      Time.use_zone(timezone) do
        super do
          with(:has_event_data, true) if params[:with_event_data_only].present?
          with(:spent).greater_than(0) if params[:with_expenses_only].present?
          with(:has_surveys, true) if params[:with_surveys_only].present?
          with(:has_comments, true) if params[:with_comments_only].present?

          if params.key?(:event_data_stats) && params[:event_data_stats]
            stat(:promo_hours, type: 'sum')
            stat(:impressions, type: 'sum')
            stat(:interactions, type: 'sum')
            stat(:samples, type: 'sum')
            stat(:spent, type: 'sum')
            stat(:gender_female, type: 'mean')
            stat(:gender_male, type: 'mean')
            stat(:gender_male, type: 'mean')
            stat(:ethnicity_asian, type: 'mean')
            stat(:ethnicity_black, type: 'mean')
            stat(:ethnicity_hispanic, type: 'mean')
            stat(:ethnicity_native_american, type: 'mean')
            stat(:ethnicity_white, type: 'mean')
          end
        end
      end
    end

    def search_facets
      current_company = Company.current || Company.new
      proc do
        facet :campaign_id
        facet :place_id
        facet :user_ids
        facet :team_ids
        facet :status do
          row(:late) do
            with(:status, 'Unsent')
            with(search_end_date_field).less_than(current_company.late_event_end_date)
          end
          row(:due) do
            with(:status, 'Unsent')
            with(search_end_date_field, current_company.due_event_start_date..current_company.due_event_end_date)
          end
          row(:rejected) do
            with(:status, 'Rejected')
          end
          row(:submitted) do
            with(:status, 'Submitted')
          end
          row(:approved) do
            with(:status, 'Approved')
          end
          row(:active) do
            with(:status, 'Active')
          end
          row(:inactive) do
            with(:status, 'Inactive')
          end
          row(:executed) do
            with(:status, 'Active')
            with(search_end_date_field).less_than(Time.zone.now.beginning_of_day)
          end
          row(:scheduled) do
            with(:status, 'Active')
            with(search_end_date_field).greater_than(Time.zone.now.beginning_of_day)
          end
        end

        facet :start_at do
          row(:today) do
            with(search_start_date_field).less_than(Time.zone.now.end_of_day)
            with(search_end_date_field).greater_than(Time.zone.now.beginning_of_day)
          end
        end
      end
    end

    def searchable_params
      [:start_date, :end_date, :page, :sorting, :sorting_dir, :per_page,
       campaign: [], area: [], user: [], team: [], event_status: [], brand: [], status: [],
       venue: [], role: [], brand_portfolio: [], id: [], event: []]
    end

    def search_start_date_field
      if Company.current && Company.current.timezone_support?
        :local_start_at
      else
        :start_at
      end
    end

    def search_end_date_field
      if Company.current && Company.current.timezone_support?
        :local_end_at
      else
        :end_at
      end
    end

    def total_promo_hours_for_places(places)
      where(place_id: places).sum(:promo_hours)
    end

    def report_fields
      if Company.current.present? && Company.current.timezone_support?
        prefix = 'local_'
        start_time_filter = 'local_start_at::time'
        end_time_filter   = 'local_end_at::time'
      else
        timezone = ActiveSupport::TimeZone.zones_map[Time.zone.name].tzinfo.identifier
        prefix = ''
        start_time_filter = "(TIMEZONE('UTC', start_at) AT TIME ZONE '#{timezone}')::time"
        end_time_filter   = "(TIMEZONE('UTC', end_at) AT TIME ZONE '#{timezone}')::time"
      end
      {
        start_date:   { title: 'Start date', column: -> { "to_char(#{prefix}start_at, 'YYYY/MM/DD')" },
                        filter_column: -> { "#{prefix}start_at" },
                        filter: ->(_field) { { name: 'event:start_date', type: 'calendar' } } },
        start_time:   { title: 'Start time', column: -> { "to_char(#{prefix}start_at, 'HH12:MI AM')" },
                        filter_column: -> { start_time_filter },
                        filter: ->(field) { { name: 'event:start_time', type: 'time', label: field.label  } } },
        end_date:     { title: 'End date', column: -> { "to_char(#{prefix}end_at, 'YYYY/MM/DD')" },
                        filter_column: -> { "#{prefix}end_at" },
                        filter: ->(_field) { { name: 'event:end_date', type: 'calendar' } } },
        end_time:     { title: 'End time', column: -> { "to_char(#{prefix}end_at, 'HH12:MI AM')" },
                        filter_column: -> { end_time_filter },
                        filter: ->(field) { { name: 'event:end_time', type: 'time', label: field.label } } },
        event_active: { title: 'Active State', filter_column: -> { 'events.active' },
                        filter: lambda do |field|
                          { name: 'event:event_active',
                            label: field.label, items: [
                              { id: 'true', label: 'Active', count: 1, name: 'event:event_active' },
                              { id: 'false', label: 'Inactive', count: 1, name: 'event:event_active' }] }
                        end },
        event_status: { title: 'Event Status' }
      }
    end
  end

  def team_members
    team_ids.map { |id| "team:#{id}" } + user_ids.map { |id| "company_user:#{id}" }
  end

  def team_members=(members)
    self.user_ids = members.select { |member| member =~ /^company_user:[0-9]+$/ }.map { |member| member.split(':')[1] }
    self.team_ids = members.select { |member| member =~ /^team:[0-9]+$/ }.map { |member| member.split(':')[1] }
  end

  def start_at
    localize_date(:start_at)
  end

  def end_at
    localize_date(:end_at)
  end

  private

  def valid_campaign?
    return unless campaign_id.present? && (new_record? || campaign_id_changed?)

    errors.add :campaign_id, :invalid if valid_campaign_for_current_user.where(id: campaign_id).empty?
  end

  def valid_campaign_for_current_user
    if User.current.present? && User.current.current_company_user.present?
      Campaign.accessible_by_user(User.current.current_company_user)
    else
      Campaign.where(company_id: company_id)
    end
  end

  # Copy some errors to the attributes used on the forms so the user
  # can see them
  def delegate_errors
    errors[:start_at].each { |e| errors.add(:start_date, e) }
    errors[:end_at].each { |e| errors.add(:end_date, e) }
    place.errors.full_messages.each { |e| errors.add(:place_reference, e) } if place
  end

  def parse_start_end
    unless start_date.nil? || start_date.empty?
      self.start_at = Timeliness.parse([start_date, start_time.to_s.strip].compact.join(' ').strip, zone: :current)
    end
    return if end_date.nil? || end_date.empty?
    self.end_at = Timeliness.parse([end_date, end_time.to_s.strip].compact.join(' ').strip, zone: :current)
  end

  # Sets the values for start_date, start_time, end_date and end_time when from start_at and end_at
  def set_start_end_dates
    if new_record?
      self.start_time ||= '12:00 PM'
      self.end_time ||= '01:00 PM'
      parse_start_end
    elsif has_attribute?(:start_at) # this if is to allow custom selects on the Event module
      self.start_date = start_at.to_s(:slashes)   unless start_at.blank?
      self.start_time = start_at.to_s(:time_only).strip unless start_at.blank?
      self.end_date   = end_at.to_s(:slashes)     unless end_at.blank?
      self.end_time   = end_at.to_s(:time_only).strip   unless end_at.blank?
    end
  end

  def between_visit_date_range
    return unless start_at && end_at && !visit_id.blank?
    visit = BrandAmbassadors::Visit.find(visit_id)
    visit_start_date = visit.start_date.to_date
    visit_end_date = visit.end_date.to_date
    if start_at.to_date < visit_start_date
      errors.add(:start_date, "should be after #{visit_start_date - 1}")
    end

    return unless end_at.to_date > visit_end_date
    errors.add(:end_date, "should be before #{visit_end_date + 1}")
  end

  def after_remove_member(member)
    if member.is_a? Team
      users = member.user_ids - user_ids
    else
      users = [member]
    end

    tasks.where(company_user_id: users).update_all(company_user_id: nil)
    Sunspot.index(tasks)
  end

  def check_results_changed
    @refresh_event_data = false
    if results.any?(&:changed?) || event_expenses.any?(&:changed?)
      @refresh_event_data = true
    end

    @reindex_place = place_id_changed?
    @reindex_tasks = active_changed?

    true
  end

  def generate_event_data_record
    if @refresh_event_data
      build_event_data unless event_data.present?
      event_data.update_data
      event_data.save
    end

    true
  end

  def reindex_associated
    reindex_campaign

    if @reindex_place
      Resque.enqueue(EventPhotosIndexer, id)
      if place_id_was.present?
        previous_venue = Venue.find_by(company_id: company_id, place_id: place_id_was)
        Resque.enqueue(VenueIndexer, previous_venue.id) unless previous_venue.nil?
      end
    end

    Sunspot.index tasks if @reindex_tasks
  end

  def reindex_campaign
    return unless campaign.present?
    campaign.first_event = self if campaign.first_event_at.nil? || campaign.first_event_at > start_at
    campaign.last_event  = self if campaign.last_event_at.nil?  || campaign.last_event_at  < start_at
    campaign.save if campaign.changed?
  end

  def index_venue
    Resque.enqueue(VenueIndexer, venue.id) if place_id.present?
    true
  end

  def set_promo_hours
    self.promo_hours = (end_at - start_at) / 3600
    true
  end

  # Validates that the user can schedule a event on tha specified place. The validation
  # is only made if the place_id changed or it's being created
  def event_place_valid?
    return unless place_id_changed? || self.new_record?
    if place.nil? || campaign.nil?
      validate_place_presence
    else
      validate_place_valid_for_campaign
      validate_user_allowed_schedule_event_in_place
    end
  end

  def validate_place_presence
    return unless place.nil? && User.current.present? &&
                  User.current.current_company_user.present? &&
                  !User.current.current_company_user.is_admin?
    errors.add(:place_reference, 'cannot be blank')
  end

  def validate_place_valid_for_campaign
    return if campaign.place_allowed_for_event?(place)
    errors.add(:place_reference,
               'This place has not been approved for the selected campaign. '\
               'Please contact your campaign administrator to request that this be updated.')
  end

  def validate_user_allowed_schedule_event_in_place
    return if User.current.nil? || User.current.current_company_user.nil? ||
              User.current.current_company_user.allowed_to_access_place?(place)
    errors.add(:place_reference,
               'You do not have permissions to this place. '\
               'Please contact your campaingn administrator to request access.')
    errors.add(:place_reference, 'is not part of your authorized locations')
  end

  def set_event_timezone
    return unless new_record? || start_at_changed? || end_at_changed?
    self.timezone = Time.zone.tzinfo.identifier
    assign_local_time_attribute(:start_at)
    assign_local_time_attribute(:end_at)
  end

  def assign_local_time_attribute(attribute)
    return if self[attribute].nil?
    self["local_#{attribute}".to_sym] = Timeliness.parse(self[attribute].strftime('%Y-%m-%d %H:%M:%S'),
                                                         zone: 'UTC')
  end

  def update_activities
    activities.update_all(campaign_id: campaign_id) if campaign_id_changed?
  end

  def localize_date(attribute)
    date = self[attribute]
    if date && timezone && Company.current && Company.current.timezone_support? && Company.current.id == company_id
      date = Timeliness.parse(date.in_time_zone(timezone).strftime('%Y-%m-%d %H:%M:%S'), zone: timezone)
    end
    date
  end

  def create_notifications
    if company.event_alerts_policy == Notification::EVENT_ALERT_POLICY_ALL
      Resque.enqueue(EventNotifierWorker, id)
    end
    true
  end
end
