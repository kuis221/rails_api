# == Schema Information
#
# Table name: events
#
#  id            :integer          not null, primary key
#  campaign_id   :integer
#  company_id    :integer
#  start_at      :datetime
#  end_at        :datetime
#  aasm_state    :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  active        :boolean          default(TRUE)
#  place_id      :integer
#  promo_hours   :decimal(6, 2)    default(0.0)
#  reject_reason :text
#  summary       :text
#  timezone      :string(255)
#

class Event < ActiveRecord::Base
  include AASM

  belongs_to :campaign
  belongs_to :place, autosave: true

  has_many :tasks, :order => 'due_at ASC', dependent: :destroy, inverse_of: :event
  has_many :photos, conditions: {asset_type: 'photo'}, class_name: 'AttachedAsset', :as => :attachable, inverse_of: :attachable, order: "created_at DESC"
  has_many :documents, conditions: {asset_type: 'document'}, class_name: 'AttachedAsset', :as => :attachable, inverse_of: :attachable, order: "created_at DESC"
  has_many :teamings, :as => :teamable
  has_many :teams, :through => :teamings, :after_remove => :after_remove_member
  has_many :results, class_name: 'EventResult', inverse_of: :event do
    def active
      where(form_field_id: proxy_association.owner.campaign.form_field_ids)
    end
  end
  has_many :event_expenses, inverse_of: :event, autosave: true
  has_one :event_data, autosave: true

  has_many :comments, :as => :commentable, order: 'comments.created_at ASC'

  has_many :surveys,  inverse_of: :event

  # Events-Users relationship
  has_many :memberships, :as => :memberable
  has_many :users, :class_name => 'CompanyUser', source: :company_user, :through => :memberships, :after_remove => :after_remove_member

  has_many :contact_events

  accepts_nested_attributes_for :surveys
  accepts_nested_attributes_for :results
  accepts_nested_attributes_for :photos
  accepts_nested_attributes_for :comments, reject_if: proc {|attributes| attributes['content'].blank? }

  scoped_to_company

  attr_accessor :place_reference

  scope :upcomming, lambda{ where('start_at >= ?', Time.zone.now) }
  scope :active, lambda{ where(active: true) }
  scope :between_dates, lambda {|start_date, end_date|
    prefix = ''
    if Company.current.present? && Company.current.timezone_support?
      prefix = 'local_'
      start_date = start_date.strftime('%Y-%m-%d %H:%M:%S')
      end_date = end_date.strftime('%Y-%m-%d %H:%M:%S')
    end
    where("#{prefix}end_at > ? AND #{prefix}start_at < ?", start_date, end_date)
  }

  scope :by_campaigns, lambda{|campaigns| where(campaign_id: campaigns) }
  scope :with_user_in_team, lambda{|user|
    joins('LEFT JOIN "teamings" t ON "t"."teamable_id" = "events"."id" AND "t"."teamable_type" = \'Event\' LEFT JOIN "memberships" m ON "m"."memberable_id" = "events"."id" AND "m"."memberable_type" = \'Event\'').
    where('t.team_id in (?) OR m.company_user_id IN (?)', user.team_ids, user) }
  scope :in_past, lambda{ where('events.end_at < ?', Time.now) }
  scope :with_team, lambda{|team|
    joins(:teamings).
    where(teamings: {team_id: team} ) }

  scope :for_campaigns_accessible_by, lambda{|company_user| company_user.is_admin? ? scoped() : where(campaign_id: company_user.accessible_campaign_ids+[0]) }

  scope :accessible_by_user, ->(company_user) { company_user.is_admin? ? scoped() : for_campaigns_accessible_by(company_user).in_user_accessible_locations(company_user) }

  scope :in_user_accessible_locations, ->(company_user) { company_user.is_admin? ? scoped() : joins(:place).where('events.place_id in (?) or events.place_id in (select place_id FROM locations_places where location_id in (?))', company_user.accessible_places+[0], company_user.accessible_locations+[0]) }

  track_who_does_it

  #validates_attachment_content_type :file, :content_type => ['image/jpeg', 'image/png']
  validates :campaign_id, presence: true, numericality: true
  validate :valid_campaign?
  validates :company_id, presence: true, numericality: true
  validates :start_at, presence: true
  validates :end_at, presence: true

  DATE_FORMAT = /^[0-1]?[0-9]\/[0-3]?[0-9]\/[0-2]0[0-9][0-9]$/
  validates :start_date, format: { with: DATE_FORMAT, message: 'MM/DD/YYYY' }
  validates :end_date, format: { with: DATE_FORMAT, message: 'MM/DD/YYYY' }

  validate :event_place_valid?

  validates_datetime :start_at
  validates_datetime :end_at, :on_or_after => :start_at, on_or_after_message: 'must be after'

  attr_accessor :start_date, :start_time, :end_date, :end_time

  after_initialize :set_start_end_dates
  before_validation :parse_start_end
  after_validation :delegate_errors

  after_validation :set_event_timezone

  before_save :set_promo_hours, :check_results_changed, :add_current_company_user
  after_save :reindex_associated
  after_commit :index_venue

  delegate :latitude,:state_name,:longitude,:formatted_address,:name_with_location, to: :place, prefix: true, allow_nil: true
  delegate :impressions, :interactions, :samples, :spent, :gender_female, :gender_male, :ethnicity_asian, :ethnicity_black, :ethnicity_hispanic, :ethnicity_native_american, :ethnicity_white, to: :event_data, allow_nil: true

  aasm do
    state :unsent, :initial => true
    state :submitted
    state :approved
    state :rejected

    event :submit do
      transitions :from => [:unsent, :rejected], :to => :submitted, :guard => :valid_results?
    end

    event :approve do
      transitions :from => :submitted, :to => :approved
    end

    event :reject do
      transitions :from => :submitted, :to => :rejected
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
      has_event_data?
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

  def place_reference=(value)
    @place_reference = value
    if value and value.present?
      if value =~ /^[0-9]+$/
        self.place = Place.find(value)
      else
        reference, place_id = value.split('||')
        self.place = Place.load_by_place_id(place_id,  reference)
      end
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
    self.aasm_state.capitalize
  end

  def in_past?
    end_at < Time.now
  end

  def in_future?
    start_at > Time.now
  end

  def is_late?
    end_at.to_date <= (2.days.ago).to_date
  end

  def happens_today?
    start_at.to_date <= Time.zone.now.to_date && end_at.to_date >= Time.zone.now.to_date
  end

  def was_yesterday?
    end_at.to_date == (Time.zone.now.to_date-1)
  end

  def has_event_data?
    campaign.present? && (results.where(form_field_id: campaign.form_fields.for_event_data.pluck(:id)).where('event_results.value is not null AND event_results.value <> \'\'').count > 0)
  end

  def venue
    unless place_id.nil?
      @venue ||= Venue.find_or_create_by_company_id_and_place_id(company_id, place_id)
      @venue.place = self.place if self.association(:place).loaded?
    end
    @venue
  end

  def contacts
    @contacts ||= contact_events.map(&:contactable).sort{|a, b| a.full_name <=> b.full_name }
  end

  def user_in_team?(user)
    ::Event.with_user_in_team(user).where(id: self.id).count > 0
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
      result = results.select{|r| (r.form_field_id == field.id || (field.kpi_id.present? && r.kpi_id == field.kpi_id)) && r.kpis_segment_id.nil? }.first || results.build({form_field_id: field.id, kpi_id: field.kpi_id})
      result.form_field = field
      result
    end
  end

  def segments_results_for(field)
    # The results are mapped by field or kpi_id to make it find them in case the form field was deleted and readded to the form
    if field.kpi.present?
      fs = field.kpi.kpis_segments.map do |segment|
        result = results.select{|r| (r.form_field_id == field.id || (field.kpi_id.present? && r.kpi_id == field.kpi_id)) && r.kpis_segment_id == segment.id }.first || results.build({form_field_id: field.id, kpis_segment_id: segment.id, kpi_id: field.kpi_id})
        result.form_field = field
        result.kpis_segment = segment
        result
      end
      fs
    end
  end

  # This method is a combinations of results_for and segments_results_for where it will return all
  # the segmented + non segmented results
  def all_results_for(fields)
    # The results are mapped by field or kpi_id to make it find them in case the form field was deleted and readded to the form
    fields.map do |field|
      if field.is_segmented?
        segments_results_for(field)
      else
        result = results.select{|r| (r.form_field_id == field.id || (field.kpi_id.present? && r.kpi_id == field.kpi_id)) && r.kpis_segment_id.nil? }.first || results.build({form_field_id: field.id, kpi_id: field.kpi_id})
        result.form_field = field
        result
      end
    end.flatten
  end

  def result_for_kpi(kpi)
    field = campaign.form_fields.detect{|f| f.kpi_id == kpi.id }
    if field.present?
      if field.is_segmented?
        segments_results_for(field)
      else
        results_for([field]).first
      end
    end
  end

  def results_for_kpis(kpis)
    kpis.map{|kpi| result_for_kpi(kpi) }.flatten.compact
  end

  def locations_for_index
    place.locations.pluck('locations.id') if place.present?
  end

  def kpi_goals
    unless @goals
      @goals = {}
      total_campaign_events = campaign.events.count
      if total_campaign_events > 0
        campaign.goals.base.each do |goal|
          if goal.kpis_segment_id.present?
            @goals[goal.kpi_id] ||= {}
            @goals[goal.kpi_id][goal.kpis_segment_id] = goal.value unless goal.value.nil?
          else
            @goals[goal.kpi_id] = goal.value / total_campaign_events unless goal.value.nil?
          end
        end
      end
    end
    @goals
  end

  def demographics_graph_data
    unless @demographics_graph_data
      @demographics_graph_data = {}
      [:age, :gender, :ethnicity].each do |kpi|
        scoped_results = results.send(kpi).select('event_results.kpis_segment_id, sum(event_results.scalar_value) AS segment_sum, avg(event_results.scalar_value) AS segment_avg').group('event_results.kpis_segment_id')
        segments = Kpi.send(kpi).kpis_segments
        @demographics_graph_data[kpi] = Hash[segments.map{|s| [s.text, scoped_results.detect{|r| r.kpis_segment_id == s.id}.try(:segment_avg).try(:to_f) || 0]}]
      end
    end
    @demographics_graph_data
  end

  def survey_statistics
    @survey_statistics ||= Hash.new.tap do |stats|
      stats[:total] = 0
      brands_map = Hash[campaign.survey_brands.map{|b| [b.id, b.name] }]
      surveys.each do|survey|
        stats[:total] += 1
        survey.surveys_answers.each do |answer|
          if  answer.brand_id.present? && brands_map.has_key?(answer.brand_id)
            type = "question_#{answer.question_id}"
            stats[type] ||= {}
            if answer.question_id == 2
              if answer.answer.present? && answer.answer =~ /^[0-9]+(\.[0-9])?$/
                stats[type][brands_map[answer.brand_id]] ||= {count: 0, total: 0, avg: 0}
                stats[type][brands_map[answer.brand_id]][:count] += 1
                stats[type][brands_map[answer.brand_id]][:total] += answer.answer.to_f
                stats[type][brands_map[answer.brand_id]][:avg] = stats[type][brands_map[answer.brand_id]][:total] / stats[type][brands_map[answer.brand_id]][:count]
              end
            else
              stats[type][answer.answer] ||= {}
              stats[type][answer.answer][brands_map[answer.brand_id]] ||= {count: 0, avg: 0.0}
              stats[type][answer.answer][brands_map[answer.brand_id]][:count] += 1
              stats[type].each{|a, brands| brands.each{|b, s| s[:avg] = s[:count]*100.0/stats[:total]} }
            end
          elsif answer.kpi_id.present?
            type = "kpi_#{answer.kpi_id}"
            stats[type] ||= {}
            stats[type][answer.answer] ||= {count: 0, avg: 0}
            stats[type][answer.answer][:count] += 1
            stats[type].each{|a, s| s[:avg] = s[:count]*100/stats[:total] }
          end
        end
      end
    end
  end

  # Returns true if all the results for the current campaign are valid
  def valid_results?
    # Ensure all the results have been assigned/initialized
    all_results_for(campaign.form_fields.for_event_data).all?{|r| r.valid? } if campaign.present?
  end

  def method_missing(method_name, *args)
    matches = /(place|campaign)_(.*)/.match(method_name)
    if matches && matches.length == 3
      if read_attribute("#{matches[1]}_name")
        read_attribute(method_name)
      else
        send(matches[1]).try(matches[2])
      end
    else
      super
    end
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false, &block)
      ss = solr_search do
        (start_at_field, end_at_field) = [:start_at, :end_at, Time.zone.name]
        if Company.current && Company.current.timezone_support?
          (start_at_field, end_at_field, timezone) = [:local_start_at, :local_end_at, 'UTC']
        end

        Time.use_zone(timezone) do
          company_user = params[:current_company_user]
          if company_user.present?
            unless company_user.role.is_admin?
              with(:campaign_id, company_user.accessible_campaign_ids + [0])
              any_of do
                locations = company_user.accessible_locations
                places_ids = company_user.accessible_places
                with(:place_id, places_ids + [0])
                with(:location, locations + [0])
              end
            end
          end

          if (params.has_key?(:user) && params[:user].present?) || (params.has_key?(:team) && params[:team].present?)
            team_ids = []
            team_ids += params[:team] if params.has_key?(:team) && params[:team].any?
            team_ids += Team.with_user(params[:user]).map(&:id) if params.has_key?(:user) && params[:user].any?

            any_of do
              with(:user_ids, params[:user]) if params.has_key?(:user) && params[:user].present?
              with(:team_ids, team_ids) if team_ids.any?
            end
          end

          with :location,    params[:location] if params.has_key?(:location) and params[:location].present?
          with :campaign_id, params[:campaign] if params.has_key?(:campaign) and params[:campaign].present?

          # We are using two options to allow searching by active/inactive in combination with approved/late/rejected/submitted
          with :status,      params[:status] if params.has_key?(:status) and params[:status].present? # For the active state

          if params.has_key?(:event_status) and params[:event_status].present? # For the event status
            event_status = params[:event_status].dup
            late = event_status.delete('Late')
            due = event_status.delete('Due')
            executed = event_status.delete('Executed')
            scheduled = event_status.delete('Scheduled')

            any_of do
              with(:status, event_status) unless event_status.empty?
              unless late.nil?
                all_of do
                  with(:status, 'Unsent')
                  with(end_at_field).less_than(2.days.ago)
                end
              end

              unless due.nil?
                all_of do
                  with(:status, 'Unsent')
                  with(end_at_field, Date.yesterday.beginning_of_day..Time.zone.now)
                end
              end

              unless executed.nil?
                with(end_at_field).less_than(Time.zone.now)
              end

              unless scheduled.nil?
                with(end_at_field).greater_than(Time.zone.now.beginning_of_day)
              end
            end
          end
          with(:company_id, params[:company_id])
          with(:has_event_data, true) if params[:with_event_data_only].present?
          with(:spent).greater_than(0) if params[:with_expenses_only].present?
          with(:has_surveys, true) if params[:with_surveys_only].present?
          with(:has_comments, true) if params[:with_comments_only].present?
          if params.has_key?(:brand) and params[:brand].present?
            campaing_ids = Campaign.select('DISTINCT(campaigns.id)').joins(:brands).where(brands: {id: params[:brand]}, company_id: params[:company_id]).map(&:id)
            with "campaign_id", campaing_ids + [0]
          end

          if params[:start_date].present? and params[:end_date].present?
            d1 = Timeliness.parse(params[:start_date], zone: :current).beginning_of_day
            d2 = Timeliness.parse(params[:end_date], zone: :current).end_of_day
            any_of do
              with start_at_field, d1..d2
              with end_at_field, d1..d2
            end
          elsif params[:start_date].present?
            d = Timeliness.parse(params[:start_date], zone: :current)
            all_of do
              with(start_at_field).less_than(d.end_of_day)
              with(end_at_field).greater_than(d.beginning_of_day)
            end
          end

          if params.has_key?(:q) and params[:q].present?
            (attribute, value) = params[:q].split(',')
            case attribute
            when 'brand'
              campaigns = Campaign.select('campaigns.id').joins(:brands).where(brands: {id: value}).map(&:id)
              campaigns = '-1' if campaigns.empty?
              with "campaign_id", campaigns
            when 'campaign', 'place'
              with "#{attribute}_id", value
            when 'company_user'
              with :user_ids, value
            when 'venue'
              with :place_id, Venue.find(value).place_id
            when 'area'
              any_of do
                with :place_id, Area.where(id: value).joins(:places).where(places: {is_location: false}).pluck('places.id').uniq + [0]
                with :location, Area.find(value).locations.map(&:id) + [0]
              end
            else
              with "#{attribute}_ids", value
            end
          end

          if params[:area].present?
            any_of do
              with :place_id, Area.where(id: params[:area]).joins(:places).where(places: {is_location: false}).pluck('places.id').uniq + [0]
              with :location, Area.where(id: params[:area]).map{|a| a.locations.map(&:id) }.flatten + [0]
            end
          end

          with :place_id, params[:place] if params[:place].present?

          if params.has_key?(:event_data_stats) && params[:event_data_stats]
            stat(:promo_hours, :type => "sum")
            stat(:impressions, :type => "sum")
            stat(:interactions, :type => "sum")
            stat(:samples, :type => "sum")
            stat(:spent, :type => "sum")
            stat(:gender_female, :type => "mean")
            stat(:gender_male, :type => "mean")
            stat(:gender_male, :type => "mean")
            stat(:ethnicity_asian, :type => "mean")
            stat(:ethnicity_black, :type => "mean")
            stat(:ethnicity_hispanic, :type => "mean")
            stat(:ethnicity_native_american, :type => "mean")
            stat(:ethnicity_white, :type => "mean")
          end

          if include_facets
            facet :campaign_id
            facet :place_id
            facet :user_ids
            facet :team_ids
            facet :status do
              row(:late) do
                with(:status, 'Unsent')
                with(end_at_field).less_than(2.days.ago)
              end
              row(:due) do
                with(:status, 'Unsent')
                with(end_at_field, Date.yesterday.beginning_of_day..Time.zone.now)
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
                with(end_at_field).less_than(Time.zone.now.beginning_of_day)
              end
              row(:scheduled) do
                with(:status, 'Active')
                with(end_at_field).greater_than(Time.zone.now.beginning_of_day)
              end
            end

            facet :start_at do
              row(:today) do
                with(start_at_field).less_than(Time.zone.now.end_of_day)
                with(end_at_field).greater_than(Time.zone.now.beginning_of_day)
              end
            end
          end

          order_by(params[:sorting] || start_at_field , params[:sorting_dir] || :asc)
          paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)

          yield self if block_given?
        end
      end
    end

    def total_promo_hours_for_places(places)
      where(place_id: places).sum(:promo_hours)
    end
  end

  def start_at
    localize_date(:start_at)
  end

  def end_at
    localize_date(:end_at)
  end

  private
    def valid_campaign?
      if self.campaign_id.present? && (new_record? || campaign_id_changed?)
        campaigns = Campaign.where(company_id: self.company_id)
        campaigns = campaigns.accessible_by_user(User.current.current_company_user) if User.current.present? && User.current.current_company_user.present?
        unless campaigns.where(id: self.campaign_id).count > 0
          errors.add :campaign_id, 'is not a valid'
        end
      end
    end

    # Copy some errors to the attributes used on the forms so the user
    # can see them
    def delegate_errors
      errors[:start_at].each{|e| errors.add(:start_date, e) }
      errors[:end_at].each{|e| errors.add(:end_date, e) }
      place.errors.full_messages.each{|e| errors.add(:place_reference, e) } if place
    end

    def parse_start_end
      unless self.start_date.nil? or self.start_date.empty?
        parts = self.start_date.split("/")
        self.start_at = Time.zone.parse([[parts[1],parts[0],parts[2]].join('/'), self.start_time].join(' '))
      end
      unless self.end_date.nil? or self.end_date.empty?
        parts = self.end_date.split("/")
        self.end_at = Time.zone.parse([[parts[1],parts[0],parts[2]].join('/'), self.end_time].join(' '))
      end
    end

    # Sets the values for start_date, start_time, end_date and end_time when from start_at and end_at
    def set_start_end_dates
      if new_record?
        self.start_time ||= '12:00 PM'
        self.end_time ||= '01:00 PM'
      else
        if has_attribute?(:start_at) # this if is to allow custom selects on the Event module
          self.start_date = self.start_at.to_s(:slashes)   unless self.start_at.blank?
          self.start_time = self.start_at.to_s(:time_only).strip unless self.start_at.blank?
          self.end_date   = self.end_at.to_s(:slashes)     unless self.end_at.blank?
          self.end_time   = self.end_at.to_s(:time_only).strip   unless self.end_at.blank?
        end
      end
    end

    def after_remove_member(member)
      if member.is_a? Team
        users = member.user_ids - self.user_ids
      else
        users = [member]
      end

      self.tasks.scoped_by_company_user_id(users).update_all(company_user_id: nil)
      Sunspot.index(self.tasks)
    end

    def check_results_changed
      @refresh_event_data = false
      if results.any?{|r| r.changed?} || event_expenses.any?{|e| e.changed?}
        @refresh_event_data = true
      end
      true
    end

    def reindex_associated
      if campaign.present?
        campaign.first_event = self if campaign.first_event_at.nil? || campaign.first_event_at > self.start_at
        campaign.last_event  = self if campaign.last_event_at.nil?  || campaign.last_event_at  < self.start_at
        campaign.save if campaign.changed?
      end

      if @refresh_event_data
        build_event_data unless event_data.present?
        event_data.update_data
        event_data.save
      end

      if place_id_changed?
        Resque.enqueue(EventPhotosIndexer, self.id)
        if place_id_was.present?
          previous_venue = Venue.find_by_company_id_and_place_id(company_id, place_id_was)
          Resque.enqueue(VenueIndexer, previous_venue.id) unless previous_venue.nil?
        end
      end

      if active_changed?
        Sunspot.index self.tasks
      end
    end

    def index_venue
      if place_id.present?
        Resque.enqueue(VenueIndexer, venue.id)
      end
    end

    def set_promo_hours
      self.promo_hours = (end_at - start_at) / 3600
      true
    end

    # Validates that the user can schedule a event on tha specified place. The validation
    # is only made if the place_id changed or it's being created
    def event_place_valid?
      if place_id_changed? || self.new_record?
        unless place.nil? || campaign.nil?
          unless campaign.place_allowed_for_event?(place)
            errors.add(:place_reference, 'is not valid for this campaign')
          end
          unless User.current.nil? || User.current.current_company_user.nil? || User.current.current_company_user.allowed_to_access_place?(place)
            errors.add(:place_reference, 'is not part of your authorized locations')
          end
        else
          if place.nil? && User.current.present? && User.current.current_company_user.present? && !User.current.current_company_user.is_admin?
            errors.add(:place_reference, 'cannot be blank')
          end
        end
      end
    end

    def set_event_timezone
      if new_record? || start_at_changed? || end_at_changed?
        self.timezone = Time.zone.tzinfo.identifier
        self.local_start_at = Timeliness.parse(read_attribute(:start_at).strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC') if read_attribute(:start_at)
        self.local_end_at = Timeliness.parse(read_attribute(:end_at).strftime('%Y-%m-%d %H:%M:%S'), zone: 'UTC') unless read_attribute(:end_at).nil?
      end
    end

    def localize_date(attribute)
      date = read_attribute(attribute)
      if date && timezone && Company.current && Company.current.timezone_support? && Company.current.id == company_id
        date = Timeliness.parse(date.in_time_zone(timezone).strftime('%Y-%m-%d %H:%M:%S'), zone: timezone)
      end
      date
    end

    # def add_team_members
    #   if campaign.present?
    #     campaign_team = campaign.staff.uniq
    #     if campaign_team.present?
    #       campaign_team.each do |member|
    #         if member.is_a?(CompanyUser)
    #           if member.accessible_places.include?(self.place_id)
    #             self.users << member
    #           end
    #         end
    #       end
    #       Sunspot.index self.users
    #     end
    #   end
    # end
    
    def add_current_company_user
      self.memberships.build({company_user: User.current.current_company_user}, without_protection: true) if User.current.present?
    end
end


Sunspot::Adapters::DataAccessor.register(Sunspot::Rails::Adapters::EventDataAccessor, Event)
