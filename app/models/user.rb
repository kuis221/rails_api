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
#  invitation_token       :string(60)
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string(255)
#  current_company_id     :integer
#  time_zone              :string(255)
#  detected_time_zone     :string(255)
#

class User < ActiveRecord::Base

  track_who_does_it

  include SentientUser

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable, :confirmable,
  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :trackable, :confirmable

  has_many :company_users, autosave: true

  has_many :companies, through: :company_users, order: 'companies.name ASC'
  belongs_to :current_company, class_name: 'Company'

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :detected_time_zone, allow_nil: true, :inclusion => { :in => ActiveSupport::TimeZone.all.map{ |m| m.name.to_s } }

  with_options unless: :inviting_user_or_invited? do |user|
    user.validates :country, presence: true
    user.validates :state,   presence: true
    user.validates :city,    presence: true
    user.validates :time_zone,    presence: true, :inclusion => { :in => ActiveSupport::TimeZone.all.map{ |m| m.name.to_s }  }
    user.validates :password, presence: true, if: :should_require_password?
    user.validates :password, confirmation: true, if: :password
  end

  #validates_associated :company_users

  validates_uniqueness_of :email, :allow_blank => true, :if => :email_changed?
  validates_format_of     :email, :with  => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, :allow_blank => true, :if => :email_changed?

  validates_length_of     :password, :within => 8..128, :allow_blank => true
  validates_format_of     :password, :with  => /[A-Z]/, :allow_blank => true, :message => 'should have at least one upper case letter'
  validates_format_of     :password, :with  => /[0-9]/, :allow_blank => true, :message => 'should have at least one digit'
  validates_confirmation_of :password

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :role_id, :inviting_user, :filling_profile, :company_users_attributes, as: :admin
  attr_accessible :first_name, :last_name, :email, :country, :state, :city, :password, :password_confirmation, :accepting_invitation, :time_zone

  accepts_nested_attributes_for :company_users, allow_destroy: false

  delegate :name, :id, to: :role, prefix: true, allow_nil: true

  scope :active, where('invitation_accepted_at is not null')
  scope :active_in_company, lambda{|company| active.joins(:company_users).where(company_users: {company_id: company, active: true}) }

  # Tasks-Users relationship
  has_many :tasks, through: :company_users

  has_many :events, through: :company_users

  after_save :reindex_related

  attr_accessor :inviting_user
  attr_accessor :updating_user
  attr_accessor :accepting_invitation

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

  def inactive_message
    if company_users.any?{|cu| cu.role.active?}
      super
    elsif company_users.any?{|cu| cu.active?}
      :invalid
    else
      super
    end
  end

  def role
    @role ||= current_company_user.try(:role)
  end

  def current_company_user
    @current_company_user ||= begin
      if User.current && User.current.current_company
        if company_users.loaded?
          company_users.select{|cu| cu.company_id ==  User.current.current_company.id}.first
        else
          company_users.where(company_id: User.current.current_company).first
        end
      end
    end
  end

  def inviting_user_or_invited?
    self.inviting_user || (invited_to_sign_up? and !accepting_invitation) || self.updating_user
  end

  def should_require_password?
    accepting_invitation
  end

  def reindex_related
    if first_name_changed? or last_name_changed?
      Sunspot.index self.tasks.includes([{:company_user => :user}, :event]).all
      Sunspot.commit
    end
  end

  class << self

    def inviter_role(inviter)
      return :admin if inviter.is_a?(User)
      :default
    end

    # Attempt to find a user by its email. If a record is found, send new
    # password instructions to it. If user is not found, returns a new user
    # with an email not found error.
    # Attributes must contain the user's email
    def send_reset_password_instructions(attributes={})
      recoverable = User.joins(:company_users => :role).where(company_users: {active: true}, roles:{active: true}).where(["lower(users.email) = ?", attributes[:email].downcase]).first
      if recoverable.nil?
        recoverable = User.new(attributes)
        recoverable.errors.add(:base, :reset_email_not_found)
      else
        recoverable = User.find(recoverable.id)
        recoverable.send_reset_password_instructions if recoverable.persisted?
      end
      recoverable
    end
  end
end
