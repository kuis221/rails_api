# == Schema Information
#
# Table name: tags
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  company_id    :integer
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Tag < ActiveRecord::Base
  track_who_does_it

  validates :name, presence: true, uniqueness: true

  # Campaigns-Brands relationship
  belongs_to :company
  has_and_belongs_to_many :attached_assets


  #scope :accessible_by_user, lambda{|user| scoped }

end
