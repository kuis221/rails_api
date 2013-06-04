class Area < ActiveRecord::Base
  track_who_does_it

  attr_accessible :name, :description

  validates :name, presence: true, uniqueness: true

  def activate!
    update_attribute :active, true
  end

  def deactivate!
    update_attribute :active, false
  end
end
