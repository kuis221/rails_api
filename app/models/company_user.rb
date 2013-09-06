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

  attr_accessible :role_id
  belongs_to :user
  belongs_to :company
  belongs_to :role
  has_many :tasks

  validates :role_id, presence: true, numericality: true
  validates :company_id, presence: true, numericality: true, uniqueness: {scope: :user_id}

  attr_accessible :user_attributes, :role_id, :company_id, :team_ids, :campaign_ids, as: :admin
  attr_accessible :user_attributes

  has_many :memberships

  # Teams-Users relationship
  has_many :teams, :through => :memberships, :source => :memberable, :source_type => 'Team'

  # Campaigns-Users relationship
  has_many :campaigns, :through => :memberships, :source => :memberable, :source_type => 'Campaign'

  # Events-Users relationship
  has_many :events, :through => :memberships, :source => :memberable, :source_type => 'Event'

  # Places-Users relationship
  has_many :placeables, as: :placeable
  has_many :places, through: :placeables

  delegate :name, :full_name, :first_name, :last_name, :email, :phone_number, :role_name, :time_zone, :invited_to_sign_up?, to: :user
  delegate :full_address, :country, :state, :city, :street_address, :unit_number, :zip_code, :country_name, :state_name, to: :user
  delegate :name, to: :role, prefix: true

  scope :active, where(:active => true)
  scope :by_teams, lambda{|teams| joins(:memberships).where(memberships: {memberable_id: teams, memberable_type: 'Team'}) }
  scope :by_campaigns, lambda{|campaigns| joins(:memberships).where(memberships: {memberable_id: campaigns, memberable_type: 'Campaign'}) }
  scope :by_events, lambda{|events| joins(:memberships).where(memberships: {memberable_id: events, memberable_type: 'Event'}) }

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

    integer :team_ids, multiple: true do
      teams.map(&:id)
    end

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
  end
end
