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
#  user_group_id          :integer
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
  include AASM

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable, :confirmable,
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable

  scoped_to_company

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :user_group_id, presence: true
  validates :email, presence: true
  validates :company_id, presence: true, numericality: true

  validates :country, presence: true, if: :updating_profile
  validates :state,   presence: true, if: :updating_profile
  validates :city,    presence: true, if: :updating_profile

  validates_uniqueness_of :email, :allow_blank => true, :if => :email_changed?
  validates_format_of     :email, :with  => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, :allow_blank => true, :if => :email_changed?

  validates_presence_of     :password, :if => :updating_profile
  validates_confirmation_of :password, :if => :updating_profile
  validates_length_of       :password, :within => 8..128, :allow_blank => true
  validates_format_of     :password, :with  => /[A-Z]/, :allow_blank => true, :message => 'should have at least one upper case letter'
  validates_format_of     :password, :with  => /[0-9]/, :allow_blank => true, :message => 'should have at least one digit'

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :team_ids, :user_group_id, :country, :state
  attr_accessible :reset_password_token, :first_name, :last_name, :email, :country, :state, :city, :password, :password_confirmation, as: :profile

  after_create :generate_password, :unless => :password

  # Teams-Users relationship
  has_many :teams_users, dependent: :destroy
  has_many :teams, through: :teams_users

  belongs_to :user_group

  delegate :name, to: :user_group, prefix: true, allow_nil: true

  attr_accessor :updating_profile

  aasm do
    state :invited, :initial => true
    state :active
    state :inactive

    event :activate do
      transitions :from => [:inactive, :invited], :to => :active
    end

    event :deactivate do
      transitions :from => [:active, :invited], :to => :inactive
    end
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
    super && active?
  end

  private
    def generate_password
      generate_reset_password_token! if should_generate_reset_token?
      UserMailer.password_generation(self).deliver
    end
end
