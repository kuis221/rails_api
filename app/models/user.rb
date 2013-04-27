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
#  teams_count            :integer
#  user_group_id          :integer
#

class User < ActiveRecord::Base
  include SentientUser
  include AASM

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable, :confirmable,
  devise :database_authenticatable,
         :recoverable, :rememberable, :trackable


  validates :first_name, presence: true
  validates :last_name, presence: true
  validates_presence_of   :email
  validates_uniqueness_of :email, :allow_blank => true, :if => :email_changed?
  validates_format_of     :email, :with  => /\A[^@]+@[^@]+\z/, :allow_blank => true, :if => :email_changed?

  # Setup accessible (or protected) attributes for your model
  attr_accessible :email, :password, :password_confirmation, :remember_me, :first_name, :last_name, :team_ids, :user_group_id

  after_create :generate_password, :unless => :password

  # Teams-Users relationship
  has_many :teams_users
  has_many :teams, :through => :teams_users

  belongs_to :user_group

  delegate :name, to: :user_group, prefix: true, allow_nil: true

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
    "#{first_name} #{last_name}"
  end

  private
    def generate_password
      generate_reset_password_token! if should_generate_reset_token?
      UserMailer.password_generation(self).deliver
    end

end
