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
  attr_accessible :name, :admin_email

  attr_accessor :admin_email

  has_many :company_users
  has_many :teams
  has_many :campaigns
  has_many :roles
  has_many :brand_portfolios
  has_many :events
  has_many :areas
  has_many :date_ranges
  has_many :day_parts

  validates :name, presence: true, uniqueness: true
  validates :admin_email, presence: true

  validates_format_of :admin_email, :with => /\A[^@\s]+@([^@\s]+\.)+[^@\s]+\z/, :allow_blank => true

  after_create :create_admin_role_and_user

  private
    def create_admin_role_and_user
      if admin_email
        role = self.roles.create(name: 'Admin')
        if user = User.where(["lower(users.email) = '%s'", admin_email.downcase]).first
          new_company_user = self.company_users.create({role_id: role.id, user: user}, without_protection: true)
          UserMailer.company_existing_admin_invitation(user, self).deliver
        else
          new_user = User.create({email: admin_email, first_name: 'Admin', last_name: 'User', inviting_user: true}, as: :admin)
          new_company_user = self.company_users.create({role_id: role.id, user: new_user}, without_protection: true)
          new_user.skip_invitation = true
          new_user.invite!
          UserMailer.company_admin_invitation(new_user).deliver
        end
      end
    end

end
