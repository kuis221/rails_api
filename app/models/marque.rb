# == Schema Information
#
# Table name: marques
#
#  id         :integer          not null, primary key
#  brand_id   :integer
#  name       :string(255)
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Marque < ActiveRecord::Base
  belongs_to :brand

  validates :name, presence: true

  scope :accessible_by_user, lambda{|user| all }
end
