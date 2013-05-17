# == Schema Information
#
# Table name: brands
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#

class Brand < ActiveRecord::Base
  track_who_does_it

  attr_accessible :name, :campaigns_ids

  validates :name, presence: true

  # Campaigns-Brands relationship
  has_and_belongs_to_many :campaigns

end
