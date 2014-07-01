# == Schema Information
#
# Table name: satisfaction_surveys
#
#  id              :integer          not null, primary key
#  company_user_id :integer
#  session_id      :string(255)
#  rating          :string(255)
#  feedback        :text
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#

class SatisfactionSurvey < ActiveRecord::Base
  RATING_OPTIONS = ['neutral', 'negative', 'positive']
  scoped_to_company

  belongs_to :company_user
  has_one :company, :through => :company_user

  validates :rating, presence: true, inclusion: { in: RATING_OPTIONS }
  validates :session_id, uniqueness: { scope: :company_user_id }
end
