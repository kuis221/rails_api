# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  first_name             :string(255)
#  last_name              :string(255)
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default("")
#  reset_password_token   :string(255)
#  reset_password_sent_at :datetime
#  remember_created_at    :datetime
#  sign_in_count          :integer          default(0)
#  current_sign_in_at     :datetime
#  last_sign_in_at        :datetime
#  current_sign_in_ip     :string(255)
#  last_sign_in_ip        :string(255)
#  confirmation_token     :string(255)
#  confirmed_at           :datetime
#  confirmation_sent_at   :datetime
#  unconfirmed_email      :string(255)
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  country                :string(4)
#  state                  :string(255)
#  city                   :string(255)
#  created_by_id          :integer
#  updated_by_id          :integer
#  last_activity_at       :datetime
#  invitation_token       :string(60)
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string(255)
#

class User < ActiveRecord::Base

  track_who_does_it

  include SentientUser

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable, :confirmable,
  devise :invitable, :database_authenticatable, :timeoutable,
         :recoverable, :rememberable, :trackable

  has_many :company_users, autosave: true
  has_many :companies, through: :company_users, order: 'companies.name ASC'

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true

  with_options unless: :inviting_user_or_invited?  do |user|
    user.validates :country, presence: true
    user.validates :state,   presence: true
    user.validates :city,    presence: true
    user.validates :password, presence: true, if: :should_require_password?
    user.validates :password, confirmation: true, if: :password
  end

  accepts_nested_attributes_for :company_users
  validates_associated :company_users

  validates_uniqueness_of :email, :allow_blank => true, :if => :email_changed?
  validates_format_of     :email, :with  => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, :allow_blank => true, :if => :email_changed?

  validates_length_of     :password, :within => 8..128, :allow_blank => true
  validates_format_of     :password, :with  => /[A-Z]/, :allow_blank => true, :message => 'should have at least one upper case letter'
  validates_format_of     :password, :with  => /[0-9]/, :allow_blank => true, :message => 'should have at least one digit'
  validates_confirmation_of :password

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :team_ids, :role_id, :company_users_attributes, :inviting_user, :filling_profile, as: :admin
  attr_accessible :first_name, :last_name, :email, :country, :state, :city, :password, :password_confirmation, :accepting_invitation

  # Teams-Users relationship
  has_many :teams_users, dependent: :destroy
  has_many :teams, through: :teams_users

  # Campaigns-Users relationship
  has_many :campaigns_users, dependent: :destroy
  has_many :campaigns, through: :campaigns_users

  delegate :role, to: :current_company_user, allow_nil: true
  delegate :name, :id, to: :role, prefix: true, allow_nil: true

  scope :active, where('invitation_accepted_at is not null')
  scope :active_in_company, lambda{|company| active.joins(:company_users).where(company_users: {company_id: company, active: true}) }

  # Tasks-Users relationship
  has_many :tasks

  has_and_belongs_to_many :events

  scope :with_text, lambda{|text| where('users.first_name ilike ? or users.last_name ilike ? or users.email ilike ?', "%#{text}%", "%#{text}%", "%#{text}%") }
  scope :by_teams, lambda{|teams| joins(:teams_users).where(teams_users: {team_id: teams}) }
  scope :by_campaigns, lambda{|campaigns| joins(:campaigns_users).where(campaigns_users: {campaign_id: campaigns}) }
  scope :by_events, lambda{|events| joins(:events).where(events: {id: events}) }

  searchable do
    integer :id

    text :name do
      full_name
    end
    text :email

    string :first_name
    string :last_name
    string :email

    string :role_ids, :multiple => true do
      company_users.map{|cu| "#{cu.company_id}-#{cu.role_id}" }
    end

    integer :active_company_ids, :multiple => true, :references => Company do
      company_users.where(active: true).map(&:company_id)
    end

    integer :inactive_company_ids, :multiple => true, :references => Company do
      company_users.where(active: false).map(&:company_id)
    end

    integer :team_ids, :multiple => true, :references => Team
    integer :campaign_ids, :multiple => true
  end

  attr_accessor :inviting_user
  attr_accessor :accepting_invitation

  def active?
    !invited_to_sign_up? && current_company_user && current_company_user.active?
  end

  def active_status(company_id)
    invited_to_sign_up? ? 'Invited' : (company_users.select{|cu| cu.company_id == company_id and cu.active? }.any? ? 'Active' : 'Inactive')
  end

  def activate!
    current_company_user.update_attribute(:active, true) if current_company_user
  end

  def deactivate!
    current_company_user.update_attribute(:active, false) if current_company_user
  end

  def full_name
    "#{first_name} #{last_name}".strip
  end
  alias_method :name, :full_name

  def full_address
    address = Array.new
    city_parts = []
    city_parts.push city unless city.nil?
    city_parts.push state unless state.nil?
    address.push city_parts.join(', ') unless city_parts.empty?
    address.push country_name unless country_name.nil?
    address.compact.join('<br />').html_safe
  end

  def country_name
    load_country.name rescue nil unless load_country.nil?
  end

  def state_name
    load_country.states[state]['name'] rescue nil if load_country and state
  end

  def load_country
    @the_country ||= Country.new(country) if country
  end

  # Method for Devise to make that only active users can login into the app
  def active_for_authentication?
    super && company_users.any?{|cu| cu.active? && cu.role.active?}
  end

  # This should be assigned every time the
  def current_company=(company)
    @company = company
    @current_company_user = company_users.select{|cu| cu.company_id == company.id  }.first unless company.nil?
    @role = @current_company_user.role unless @current_company_user.nil?
    @company
  end

  def current_company
    @company
  end

  def role
    @role ||= current_company_user.try(:role)
  end

  def current_company_user
    if User.current && User.current.current_company
      if company_users.loaded?
        @current_company_user ||= company_users.select{|cu| cu.company_id ==  User.current.current_company.id}.first
      else
        @current_company_user ||= company_users.where(company_id: User.current.current_company).first
      end
      @current_company_user
    end
  end

  def inviting_user_or_invited?
    inviting_user or (invited_to_sign_up? and !accepting_invitation)
  end

  def should_require_password?
    accepting_invitation
  end

  class << self

    def inviter_role(inviter)
      return :admin if inviter.is_a?(User)
      :default
    end

    # We are calling this method do_search to avoid conflicts with other gems like meta_search used by ActiveAdmin
    def do_search(params, include_facets=false)
      ss = solr_search do

        any_of do
          with(:active_company_ids, params[:company_id]) # For the active users
          with(:inactive_company_ids, params[:company_id])  # For the inactive users
        end
        with(:campaign_ids, params[:campaign]) if params.has_key?(:campaign) and params[:campaign]
        with(:team_ids, params[:team]) if params.has_key?(:team) and params[:team]
        if params.has_key?(:q) and params[:q].present?
          (attribute, value) = params[:q].split(',')
          case attribute
          when 'user'
            with :id, value
          when 'role'
            with :role_ids, "#{params[:company_id]}-#{value}"
          else
            with "#{attribute}_ids", value
          end
        end

        order_by(params[:sorting] || :name, params[:sorting_dir] || :desc)
        paginate :page => (params[:page] || 1), :per_page => (params[:per_page] || 30)
      end
    end

  end
end
