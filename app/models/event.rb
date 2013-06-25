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
#

class Event < ActiveRecord::Base
  belongs_to :campaign
  belongs_to :place, autosave: true

  has_many :tasks, dependent: :destroy
  has_many :documents, :as => :documentable
  has_many :teamings, :as => :teamable
  has_many :teams, :through => :teamings, :after_remove => :after_remove_member

  attr_accessible :end_date, :end_time, :start_date, :start_time, :campaign_id, :event_ids, :user_ids, :file, :place_reference

  # Events-Users relationship
  has_many :memberships, :as => :memberable
  has_many :users, :class_name => 'CompanyUser', source: :company_user, :through => :memberships, :after_remove => :after_remove_member

  scoped_to_company

  attr_accessor :place_reference

  scope :by_period, lambda{|start_date, end_date| where("start_at >= ? AND start_at <= ?", Timeliness.parse(start_date), Timeliness.parse(end_date.empty? ? start_date : end_date).end_of_day) unless start_date.nil? or start_date.empty? }
  scope :with_text, lambda{|text| where('epj.name ilike ? or ecj.name ilike ?', "%#{text}%", "%#{text}%").joins('LEFT JOIN "campaigns" "ecj" ON "ecj"."id" = "events"."campaign_id" LEFT JOIN "places" "epj" ON "epj"."id" = "events"."place_id"') }
  scope :by_campaigns, lambda{|campaigns| where(campaign_id: campaigns) }

  track_who_does_it

  #validates_attachment_content_type :file, :content_type => ['image/jpeg', 'image/png']
  validates :campaign_id, presence: true, numericality: true
  validates :company_id, presence: true, numericality: true
  validates :start_at, presence: true
  validates :end_at, presence: true

  validates_datetime :start_at
  validates_datetime :end_at, :on_or_after => :start_at

  attr_accessor :start_date, :start_time, :end_date, :end_time

  after_initialize :set_start_end_dates
  before_validation :parse_start_end
  after_validation :delegate_errors

  delegate :name, to: :campaign, prefix: true, allow_nil: true
  delegate :name,:latitude,:longitude,:formatted_address,:name_with_location, to: :place, prefix: true, allow_nil: true


  searchable do
    boolean :active
    time :start_at, :trie => true
    time :end_at, :trie => true
    string :status
    string :start_time

    integer :company_id

    integer :campaign_id
    string :campaign do
      campaign_id.to_s + '||' + campaign_name.to_s if campaign_id
    end
    string :campaign_name

    integer :place_id
    string :place do
      place_id.to_s + '||' + place_name if place_id
    end
    string :place_name
    string :location, multiple: true do
      locations = []
      unless place.nil?
        locations.push Place.encode_location(place.continent_name) if place.continent_name
        locations.push Place.encode_location([place.continent_name, place.country_name]) if place.country_name
        locations.push Place.encode_location([place.continent_name, place.country_name, place.state_name]) if place.state_name
        locations.push Place.encode_location([place.continent_name, place.country_name, place.state_name, place.city]) if  place.state_name && place.city
      end
      locations
    end

    integer :user_ids, multiple: true do
      users.map(&:id)
    end

    string :users, multiple: true, references: User do
      users.map{|u| u.id.to_s + '||' + u.name}
    end

    integer :team_ids, multiple: true do
      teams.map(&:id)
    end

    string :teams, multiple: true, references: Team do
      teams.map{|t| t.id.to_s + '||' + t.name}
    end

    string :day_names, multiple: true do
      (start_at.to_date..end_at.to_date).map{|d| Date::DAYNAMES[d.wday].downcase}.uniq
    end
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end

  def after_remove_member(member)
    if member.is_a? Team
      users = member.user_ids - self.user_ids
    else
      users = [member]
    end

    task_ids = Task.select('tasks.id').scoped_by_event_id(self).scoped_by_company_user_id(users).map(&:id)
    tasks = Task.scoped_by_id(task_ids)
    tasks.update_all(company_user_id: nil)
    Sunspot.index(tasks)
  end

  def place_reference=(value)
    if value and value != self.place_reference and !value.nil? and !value.empty?
      reference, place_id = value.split('||')
      self.place = Place.find_or_initialize_by_place_id(place_id, {reference: reference}) if value
    end
  end

  def place_reference
    self.place.name if self.place
  end

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      # TODO: probably this options should be passed by params?
      options = {include: [:campaign, :place]}
      ss = solr_search(options) do
        with(:user_ids, params[:user]) if params.has_key?(:user) and params[:user].present?
        with(:team_ids, params[:team]) if params.has_key?(:team) and params[:team].present?
        if params.has_key?(:place) and params[:place].present?
          place_ids = []
          place_paths = []
          params[:place].each do |place|
            if place =~ /^[0-9]+$/
              place_ids.push place
            else
              place_paths.push place
            end
          end
          any_of do
            if place_ids.size > 0
              with(:place_id, place_ids)
            end
            if place_paths.size > 0
              with(:location, place_paths)
            end
          end
        end
        with(:campaign_id, params[:campaign]) if params.has_key?(:campaign) and params[:campaign].present?
        with(:status,     params[:status]) if params.has_key?(:status) and params[:status].present?
        with(:company_id, params[:company_id])

        if params.has_key?(:brand) and params[:brand].present?
          with "campaign_id", Campaign.select('campaigns.id').joins(:brands).where(brands: {id: params[:brand]}).map(&:id)
        end

        with(:place_id, AreasPlace.where(area_id: params[:area]).map(&:place_id) + [0]) if params[:area].present?

        if params[:start_date].present? and params[:end_date].present?
          d1 = Timeliness.parse(params[:start_date], zone: :current).beginning_of_day
          d2 = Timeliness.parse(params[:end_date], zone: :current).end_of_day
          with :start_at, d1..d2
        elsif params[:start_date].present?
          d = Timeliness.parse(params[:start_date], zone: :current)
          with :start_at, d.beginning_of_day..d.end_of_day
        end
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'brand'
            with "campaign_id", Campaign.select('campaigns.id').joins(:brands).where(brands: {id: value}).map(&:id)
          when 'campaign', 'place'
            with "#{attribute}_id", value
          else
            with "#{attribute}_ids", value
          end
        end

        if params.has_key?(:date_range) and params[:date_range].any?
          DateRange.where(company_id: params[:company_id], id: params[:date_range]).includes(:date_items).each do |range|
            range.search_filters(self)
          end
        end

        if params.has_key?(:predefined_date) and params[:predefined_date].any?
          params[:predefined_date].each do |predefined_date|
            case predefined_date
            when 'today'
              with :start_at, Time.zone.now.beginning_of_day..Time.zone.now.end_of_day
            when 'week'
              with :start_at, Time.zone.now.beginning_of_week..Time.zone.now.end_of_week
            when 'month'
              with :start_at, Time.zone.now.beginning_of_month..Time.zone.now.end_of_month
            end
          end
        end

        if include_facets
          facet :campaign
          facet :place
          facet :users
          facet :teams
          facet :status
        end

        order_by(params[:sorting] || :start_at , params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end
  end

  private

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
        self.start_date = self.start_at.to_s(:slashes)   unless self.start_at.blank?
        self.start_time = self.start_at.to_s(:time_only) unless self.start_at.blank?
        self.end_date   = self.end_at.to_s(:slashes)     unless self.end_at.blank?
        self.end_time   = self.end_at.to_s(:time_only)   unless self.end_at.blank?
      end
    end


end
