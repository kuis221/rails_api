# == Schema Information
#
# Table name: day_parts
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  description   :text
#  active        :boolean          default(TRUE)
#  company_id    :integer
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class DayPart < ActiveRecord::Base
  # Created_by_id and updated_by_id fields
  track_who_does_it

  scoped_to_company

  attr_accessible :name, :description, :active

  validates :name, presence: true, uniqueness: {scope: :company_id}
  validates :company_id, presence: true

  has_many :day_items

  def status
    self.active? ? 'Active' : 'Inactive'
  end

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end
end
