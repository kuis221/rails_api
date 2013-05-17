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
#  active      :boolean          default(TRUE)
#  description :text
#

class Role < ActiveRecord::Base
  belongs_to :company
  scoped_to_company

  PERMISSIONS = %w{events tasks analysis campaigns users roles other_admin}

  has_many :users

  attr_accessible :name, :description, :permissions
  validates :name, presence: true

  serialize :permissions

  scope :active, where(:active => true)

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end
end
