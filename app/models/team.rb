# == Schema Information
#
# Table name: teams
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  users_count   :integer          default(0)
#  active        :boolean          default(TRUE)
#

class Team < ActiveRecord::Base
  attr_accessible :name, :description

  validates :name, presence: true

  # Teams-Users relationship
  has_many :teams_users
  has_many :users, :through => :teams_users


  scope :active, where(:active => true)

  def activate
    update_attribute :active, true
  end

  def deactivate
    update_attribute :active, false
  end

  def active_format
    active? ? 'Active' : 'Inactive'
  end
end
