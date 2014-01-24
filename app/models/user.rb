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
#  invitation_token       :string(255)
#  invitation_sent_at     :datetime
#  invitation_accepted_at :datetime
#  invitation_limit       :integer
#  invited_by_id          :integer
#  invited_by_type        :string(255)
#  current_company_id     :integer
#  time_zone              :string(255)
#  detected_time_zone     :string(255)
#  phone_number           :string(255)
#  street_address         :string(255)
#  unit_number            :string(255)
#  zip_code               :string(255)
#  authentication_token   :string(255)
#  invitation_created_at  :datetime
#

class User < ActiveRecord::Base

  track_who_does_it

  acts_as_reader

  include SentientUser

  # Include default devise modules. Others available are:
  # :confirmable,
  # :lockable, :timeoutable and :omniauthable, :confirmable,
  devise :invitable, :database_authenticatable,
         :recoverable, :rememberable, :trackable, :confirmable

  has_many :company_users, dependent: :destroy

  has_many :companies, through: :company_users, order: 'companies.name ASC'
  belongs_to :current_company, class_name: 'Company'

  validates :first_name, presence: true
  validates :last_name, presence: true
  validates :email, presence: true
  validates :detected_time_zone, allow_nil: true, :inclusion => { :in => ActiveSupport::TimeZone.all.map{ |m| m.name.to_s } }

  with_options unless: :inviting_user_or_invited? do |user|
    user.validates :phone_number, presence: true
    user.validates :country, presence: true
    user.validates :state,   presence: true
    user.validates :city,    presence: true
    user.validates :street_address,    presence: true
    user.validates :zip_code,    presence: true
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

  accepts_nested_attributes_for :company_users, allow_destroy: false

  delegate :name, :id, :permissions, to: :role, prefix: true, allow_nil: true

  scope :active, where('invitation_accepted_at is not null')
  scope :active_in_company, lambda{|company| active.joins(:company_users).where(company_users: {company_id: company, active: true}) }

  # Tasks-Users relationship
  has_many :tasks, through: :company_users

  has_many :events, through: :company_users

  before_save :ensure_authentication_token
  after_save :reindex_related
  after_invitation_accepted :reindex_company_users

  attr_accessor :inviting_user
  attr_accessor :updating_user
  attr_accessor :accepting_invitation
  attr_accessor :invitation_created_at
  attr_accessor :invitation_updated_at

  def full_name
    "#{first_name} #{last_name}".strip
  end
  alias_method :name, :full_name

	def is_fully_valid?
    if !phone_number.present? or
    !country.present? or
    !state.present? or
    !city.present? or
    !street_address.present? or
    !zip_code.present?
      return false
    else
      return true
    end
  end

  def full_address
    address = Array.new
    city_parts = []
    city_parts.push city if city.present?
    city_parts.push state if state.present?
    address.push street_address if street_address.present?
    address.push unit_number if unit_number.present?
    address.push city_parts.compact.join(', ') unless city_parts.empty?
    address.push zip_code if zip_code.present?
    address.push country_name if country_name.present?
    address.compact.compact.join('<br />').html_safe
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

  def companies_active_role
    self.company_users.select{|cu| cu.active? && cu.role.active?}.map(&:company)
  end

  def is_super_admin?
    role.is_admin? unless role.nil?
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

  def reindex_company_users
    Sunspot.index company_users.all
    Sunspot.commit
  end

  # Update password saving the record and clearing token. Returns true if
  # the passwords are valid and the record was saved, false otherwise.
  def reset_password!(new_password, new_password_confirmation)
    self.password = new_password
    self.password_confirmation = new_password_confirmation

    clear_reset_password_token
    after_password_reset

    self.save(:validate => false)
  end

  class << self

    def report_fields
      {
        first_name:     { title: 'First Name' },
        last_name:      { title: 'Last Name' },
        email:          { title: 'Email' },
        country:        { title: 'Country' },
        state:          { title: 'State' },
        city:           { title: 'City' },
        street1:        { title: 'Street 1' },
        street2:        { title: 'Street 2' }
      }
    end

    # Find a user by its confirmation token and try to confirm it.
    # If no user is found, returns a new user with an error.
    # If the user is already confirmed, create an error for the user
    # Options must have the confirmation_token
    def confirm_by_token(confirmation_token)
      confirmable = find_or_initialize_with_error_by(:confirmation_token, confirmation_token)
      confirmable.inviting_user = true
      confirmable.confirm! if confirmable.persisted?
      confirmable
    end

    # Attempt to find a user by its email. If a record is found, send new
    # password instructions to it. If user is not found, returns a new user
    # with an email not found error.
    # Attributes must contain the user's email
    def send_reset_password_instructions(attributes={})
      recoverable = User.joins(:company_users => :role).where(company_users: {active: true}, roles:{active: true}).where(["lower(users.email) = ?", attributes[:email].downcase]).first
      if recoverable.nil?
        recoverable = User.new(attributes.permit(:email))
        recoverable.errors.add(:base, :reset_email_not_found)
      else
        recoverable = User.find(recoverable.id)
        recoverable.send_reset_password_instructions if recoverable.persisted?
      end
      recoverable
    end

    # This method is overrided to remove the call to the deprected method Devise.allow_insecure_token_lookup
    # TODO: check if this was corrected on gem and remove this from this file
    def find_by_invitation_token(original_token, only_valid)
      invitation_token = Devise.token_generator.digest(self, :invitation_token, original_token)

      invitable = find_or_initialize_with_error_by(:invitation_token, invitation_token)
      if !invitable.persisted? # && Devise.allow_insecure_token_lookup
        invitable = find_or_initialize_with_error_by(:invitation_token, original_token)
      end
      invitable.errors.add(:invitation_token, :invalid) if invitable.invitation_token && invitable.persisted? && !invitable.valid_invitation?
      invitable.invitation_token = original_token
      invitable unless only_valid && invitable.errors.present?
    end
  end

  def ensure_authentication_token
    if authentication_token.blank?
      self.authentication_token = generate_authentication_token
    end
  end

  def reset_authentication_token!
    self.authentication_token = nil
    ensure_authentication_token
    save :validate => false
  end

  private

    def generate_authentication_token
      loop do
        token = Devise.friendly_token
        break token unless User.where(authentication_token: token).first
      end
    end
end
