# == Schema Information
#
# Table name: activities
#
#  id               :integer          not null, primary key
#  activity_type_id :integer
#  activitable_id   :integer
#  activitable_type :string(255)
#  active           :boolean          default(TRUE)
#  company_user_id  :integer
#  activity_date    :datetime
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Activity < ActiveRecord::Base
  belongs_to :activity_type
  belongs_to :activitable, polymorphic: true
  belongs_to :company_user

  validates :activity_type_id, numericality: true, presence: true
  validates :activitable_id, presence: true, numericality: true
  validates :activitable_type, presence: true
  validates :company_user_id, presence: true, numericality: true
  validates :activity_date, presence: true
  validates_datetime :activity_date, allow_nil: false, allow_blank: false
end
