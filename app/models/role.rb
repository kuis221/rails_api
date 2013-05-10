# == Schema Information
#
# Table name: roles
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  permissions :text
#  company_id  :integer
#

class Role < ActiveRecord::Base
  attr_accessible :name, :permissions

  belongs_to :company
  scoped_to_company

  PERMISSIONS = %w{events tasks analysis campaigns users roles other_admin}

  has_many :users

  validates :name, presence: true

  serialize :permissions

  scope :active, where(:active => true)
end
