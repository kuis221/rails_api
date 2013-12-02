# == Schema Information
#
# Table name: companies
#
#  id         :integer          not null, primary key
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Company < ActiveRecord::Base
  attr_accessor :admin_email

  has_many :company_users, dependent: :destroy
  has_many :teams, dependent: :destroy
  has_many :campaigns, dependent: :destroy
  has_many :roles, dependent: :destroy
  has_many :brand_portfolios, dependent: :destroy
  has_many :events, dependent: :destroy
  has_many :areas, dependent: :destroy
  has_many :date_ranges, dependent: :destroy
  has_many :day_parts, dependent: :destroy
  has_many :contacts, dependent: :destroy

  validates :name, presence: true, uniqueness: true
  validates :admin_email, presence: true, on: :create

  validates_format_of :admin_email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, :allow_blank => true

  after_create :create_admin_role_and_user

  private
    def create_admin_role_and_user
      if admin_email
        role = self.roles.create({name: 'Super Admin', is_admin: true}, without_protection: true)
        if user = User.where(["lower(users.email) = '%s'", admin_email.downcase]).first
          new_company_user = self.company_users.create({role_id: role.id, user: user}, without_protection: true)
          UserMailer.company_existing_admin_invitation(user, self).deliver
        else
          new_user = User.create({email: admin_email, first_name: 'Admin', last_name: 'User', inviting_user: true}, as: :admin)
          new_company_user = self.company_users.create({role_id: role.id, user: new_user}, without_protection: true)
          new_user.skip_invitation = true
          new_user.invite!
          new_user.update_attributes({invitation_sent_at: Time.now.utc}, without_protection: true)
          UserMailer.company_admin_invitation(new_user).deliver
        end
      end
    end

end
