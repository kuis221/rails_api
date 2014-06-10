# == Schema Information
#
# Table name: company_users
#
#  id               :integer          not null, primary key
#  company_id       :integer
#  user_id          :integer
#  role_id          :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  active           :boolean          default(TRUE)
#  last_activity_at :datetime
#

class CompanyUser < ActiveRecord::Base
  include GoalableModel

  belongs_to :user
  belongs_to :company
  belongs_to :role
  has_many :tasks, dependent: :nullify
  has_many :notifications, dependent: :destroy
  has_many :alerts, class_name: 'AlertsUser', dependent: :destroy

  validates :role_id, presence: true, numericality: true
  validates :company_id, presence: true, numericality: true, uniqueness: {scope: :user_id}

  has_many :memberships, dependent: :destroy
  has_many :contact_events, dependent: :destroy, as: :contactable

  # Teams-Users relationship
  has_many :teams, :through => :memberships, :source => :memberable, :source_type => 'Team'

  # Campaigns-Users relationship
  has_many :campaigns, :through => :memberships, :source => :memberable, :source_type => 'Campaign', after_add: :campaigns_changed do
    def children_of(parent)
      where(memberships: {parent_id: parent.id, parent_type: parent.class.name})
    end
  end

  # Events-Users relationship
  has_many :events, :through => :memberships, :source => :memberable, :source_type => 'Event'

  # Area-User relationship
  has_many :areas, through: :memberships, :source => :memberable, :source_type => 'Area', after_remove: :remove_child_goals_for

  # BrandPortfolio-User relationship
  has_many :brand_portfolios, through: :memberships, :source => :memberable, :source_type => 'BrandPortfolio'

  # BrandPortfolio-User relationship
  has_many :brands, through: :memberships, :source => :memberable, :source_type => 'Brand'

  # Places-Users relationship
  has_many :placeables, as: :placeable, dependent: :destroy
  has_many :places, through: :placeables

  delegate :name, :email, :phone_number, :role_name, :time_zone, :invited_to_sign_up?, to: :user
  delegate :full_address, :country, :state, :city, :street_address, :unit_number, :zip_code, :country_name, :state_name, to: :user
  delegate :is_admin?, to: :role, prefix: false

  NOTIFICATION_SETTINGS_TYPES = ['event_recap_due', 'event_recap_late', 'event_recap_pending_approval', 'event_recap_rejected',
                                 'new_event_team', 'late_task', 'late_team_task', 'new_comment', 'new_team_comment',
                                 'new_unassigned_team_task', 'new_task_assignment', 'new_campaign'
                                ]

  NOTIFICATION_SETTINGS_PERMISSIONS = {
                                        'event_recap_due' => [{action: :view_list, subject_class: Event}],
                                        'event_recap_late' => [{action: :view_list, subject_class: Event}],
                                        'event_recap_pending_approval' => [{action: :view_list, subject_class: Event}],
                                        'event_recap_rejected' => [{action: :view_list, subject_class: Event}],
                                        'new_event_team' => [{action: :view_list, subject_class: Event}],
                                        'late_task' => [{action: :index_my, subject_class: Task}],
                                        'late_team_task' => [{action: :index_team, subject_class: Task}],
                                        'new_comment' => [{action: :index_my, subject_class: Task}, {action: :index_my_comments, subject_class: Task}],
                                        'new_team_comment' => [{action: :index_team, subject_class: Task}, {action: :index_team_comments, subject_class: Task}],
                                        'new_unassigned_team_task' => [{action: :index_team, subject_class: Task}],
                                        'new_task_assignment' => [{action: :index_my, subject_class: Task}],
                                        'new_campaign' => [{action: :read, subject_class: Campaign}]
                                      }

  scope :active, where(:active => true)
  scope :by_teams, lambda{|teams| joins(:memberships).where(memberships: {memberable_id: teams, memberable_type: 'Team'}) }
  scope :by_campaigns, lambda{|campaigns| joins(:memberships).where(memberships: {memberable_id: campaigns, memberable_type: 'Campaign'}) }
  scope :by_events, lambda{|events| joins(:memberships).where(memberships: {memberable_id: events, memberable_type: 'Event'}) }

  scope :with_user_and_role, lambda{ joins([:role, :user]).includes([:role, :user]) }

  searchable do
    integer :id
    integer :company_id

    text :name, stored: true do
      full_name
    end
    text :email

    string :first_name
    string :last_name
    string :email
    string :city
    string :state
    string :country
    string :name do
      full_name
    end

    integer :role_id
    string :role do
      role_id.to_s + '||' + role_name.to_s if role_id
    end
    string :role_name

    boolean :active

    string :status do
      active_status
    end

    integer :team_ids, multiple: true
    integer :place_ids, multiple: true

    string :teams, multiple: true, references: Team do
      teams.map{|t| t.id.to_s + '||' + t.name}
    end

    integer :campaign_ids, multiple: true do
      campaigns.map(&:id)
    end

    string :campaigns, multiple: true, references: Campaign do
      campaigns.map{|c| c.id.to_s + '||' + c.name}
    end
  end

  accepts_nested_attributes_for :user, allow_destroy: false, update_only: true

  def active?
    !invited_to_sign_up? && super
  end

  def active_status
    invited_to_sign_up? ? 'Invited' : (active?  ? 'Active' : 'Inactive')
  end

  def activate!
    update_attribute(:active, true)
  end

  def deactivate!
    update_attribute(:active, false)
  end

  def find_users_in_my_teams
    @user_in_my_teams ||= CompanyUser.joins(:teams).where(teams: {company_id: company_id, id: teams.select('teams.id').active.map(&:id)}).map(&:id).uniq.reject{|aid| aid == self.id }
  end

  def accessible_campaign_ids
    @accessible_campaign_ids ||= Rails.cache.fetch("user_accessible_campaigns_#{self.id}", expires_in: 10.minutes) do
      if is_admin?
        company.campaign_ids
      else
        (
          campaign_ids +
          Campaign.scoped_by_company_id(company_id).joins(:brands).where(brands: {id: brand_ids}).pluck('campaigns.id') +
          Campaign.scoped_by_company_id(company_id).joins(:brand_portfolios).where(brand_portfolios: {id: brand_portfolio_ids}).pluck('campaigns.id')
        ).uniq
      end
    end
  end

  def accessible_locations
    @accessible_locations ||= Rails.cache.fetch("user_accessible_locations_#{self.id}", expires_in: 10.minutes) do
      (
        areas.joins(:places).where(places: { is_location: true }).pluck('places.location_id') +
        places.where(places: { is_location: true }).pluck('places.location_id')
      ).uniq.compact.map(&:to_i)
    end
  end

  def accessible_places
    @accessible_places ||= Rails.cache.fetch("user_accessible_places_#{self.id}", expires_in: 10.minutes) do
      (
        place_ids +
        self.areas.joins(:places).pluck('places.id')
      ).flatten.uniq
    end
  end

  def allowed_to_access_place?(place)
    @allowed_places_cache ||= {}
    @allowed_places_cache[place.try(:id) || place.object_id] ||= is_admin? ||
    (
      place.present? &&
      (
        place.location_ids.any?{|location| accessible_locations.include?(location)} ||
        accessible_places.include?(place.id)
      )
    )
  end

  def full_name
    "#{self.first_name} #{self.last_name}".strip
  end

  def first_name
    if self.attributes.has_key?('first_name')
      self.read_attribute('first_name')
    else
      user.try(:first_name)
    end
  end

  def last_name
    if self.attributes.has_key?('last_name')
      self.read_attribute('last_name')
    else
      user.try(:last_name)
    end
  end

  def role_name
    if self.attributes.has_key?('role_name')
      self.read_attribute('role_name')
    else
      role.try(:name)
    end
  end

  def dismissed_alert?(alert, version=1)
    alerts.where(name: alert, version: version).any?
  end

  def dismiss_alert(alert, version=1)
    alerts.find_or_create_by_name_and_version(alert, version)
  end

  def notification_setting_permission?(type)
    permissions = NOTIFICATION_SETTINGS_PERMISSIONS[type]
    if permissions.present?
      permissions.all?{|permission| self.role.has_permission?(permission[:action], permission[:subject_class])}
    end
  end

  class << self
    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      options = {include: [:user, :role]}
      ss = solr_search(options) do
        with(:company_id, params[:company_id])
        with(:campaign_ids, params[:campaign]) if params.has_key?(:campaign) and params[:campaign]
        with(:team_ids, params[:team]) if params.has_key?(:team) and params[:team]
        with(:role_id, params[:role]) if params.has_key?(:role) and params[:role].present?
        with(:status, params[:status]) if params.has_key?(:status) and params[:status].present?
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'company_user'
            with :id, value
          when 'role'
            with "#{attribute}_id", value
          when 'venue'
            with :place_ids, Venue.find(value).place_id
          else
            with "#{attribute}_ids", value
          end
        end

        if include_facets
          facet :role
          facet :teams
          facet :campaigns
          facet :status
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end

    def for_dropdown
      ActiveRecord::Base.connection.select_all(
        self.select("users.first_name || \' \' || users.last_name as name, company_users.id").
        joins(:user).order('lower(users.first_name || \' \' || users.last_name)').to_sql
      ).map{|r| [r['name'], r['id']] }
    end
  end


  private
    def campaigns_changed(campaign)
      @accessible_campaign_ids = nil
      Rails.cache.delete("user_accessible_campaigns_#{self.id}")
    end
end
