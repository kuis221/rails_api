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
#  active        :boolean          default(TRUE)
#  company_id    :integer
#

class Team < ActiveRecord::Base
  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  attr_accessible :name, :description, :user_ids, :campaigns_ids

  validates :name, presence: true
  validates :company_id, presence: true, numericality: true

  # Teams-Users relationship
  has_many :teams_users, dependent: :destroy
  has_many :users, through: :teams_users

  # Campaigns-Teams relationship
  has_and_belongs_to_many :campaigns

  scope :active, where(:active => true)

  scope :with_users, joins(:users).group('teams.id')
  scope :with_active_users, lambda{|companies| joins({:users => :company_users}).where(:company_users => {:active => true, :company_id => companies}).group('teams.id') }

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end
end
