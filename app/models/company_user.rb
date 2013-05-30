# == Schema Information
#
# Table name: company_users
#
#  id         :integer          not null, primary key
#  company_id :integer
#  user_id    :integer
#  role_id    :integer
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  active     :boolean          default(TRUE)
#

class CompanyUser < ActiveRecord::Base
  attr_accessible :role_id
  belongs_to :user
  belongs_to :company
  belongs_to :role

  validates :role_id, presence: true, numericality: true
  validates :company_id, presence: true, numericality: true, uniqueness: {scope: :user_id}


  after_create :send_company_invitation_email

  private
    def send_company_invitation_email
      if user.confirmed? && user.companies.count > 0
        UserMailer.company_invitation(user, company).deliver
      end
    end
end
