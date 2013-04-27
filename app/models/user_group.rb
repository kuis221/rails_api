# == Schema Information
#
# Table name: user_groups
#
#  id          :integer          not null, primary key
#  name        :string(255)
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  permissions :text
#

class UserGroup < ActiveRecord::Base
  attr_accessible :name, :permissions

  PERMISSIONS = %w{events tasks analysis campaigns users user_groups other_admin}

  has_many :users

  validates :name, presence: true

  serialize :permissions
end
