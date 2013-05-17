# == Schema Information
#
# Table name: users
#
#  id                     :integer          not null, primary key
#  first_name             :string(255)
#  last_name              :string(255)
#  email                  :string(255)      default(""), not null
#  encrypted_password     :string(255)      default(""), not null
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
#  aasm_state             :string(255)
#  role_id                :integer
#  country                :string(4)
#  state                  :string(255)
#  city                   :string(255)
#  company_id             :integer
#  created_by_id          :integer
#  updated_by_id          :integer
#

class User < ActiveRecord::Base

  track_who_does_it

  include SentientUser

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable, :confirmable,
  devise :database_authenticatable, :timeoutable,
         :recoverable, :rememberable, :trackable, :confirmable

  has_many :company_users, autosave: true
  has_many :companies, through: :company_users

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true

  with_options if: :updating_profile do |user|
    user.validates :country, presence: true
    user.validates :state,   presence: true
    user.validates :city,    presence: true
    user.validates :password, presence: true, confirmation: true
  end


  accepts_nested_attributes_for :company_users
  validates_associated :company_users

  validates_uniqueness_of :email, :allow_blank => true, :if => :email_changed?
  validates_format_of     :email, :with  => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, :allow_blank => true, :if => :email_changed?


  validates_length_of     :password, :within => 8..128, :allow_blank => true
  validates_format_of     :password, :with  => /[A-Z]/, :allow_blank => true, :message => 'should have at least one upper case letter'
  validates_format_of     :password, :with  => /[0-9]/, :allow_blank => true, :message => 'should have at least one digit'

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :team_ids, :role_id, :company_users_attributes
  attr_accessible :reset_password_token, :first_name, :last_name, :email, :country, :state, :city, :password, :password_confirmation, as: :profile

  # Teams-Users relationship
  has_many :teams_users, dependent: :destroy
  has_many :teams, through: :teams_users

  delegate :role, to: :current_company_user, allow_nil: true
  delegate :name, :id, to: :role, prefix: true, allow_nil: true

  scope :active, where('confirmed_at is not null')

  attr_accessor :updating_profile

  def active?
    # TODO: add check to current_company status
    confirmed? && current_company_user && current_company_user.active?
  end

  def active_status
    confirmed? ? 'Active' : 'Invited'
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
    super && company_users.any?{|cu| cu.active? }
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
end
