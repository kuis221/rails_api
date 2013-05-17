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
  attr_accessible :name

  has_many :company_users
  has_many :users, through: :company_users
  has_many :teams
  has_many :campaigns
  has_many :roles

  validates :name, presence: true
end
