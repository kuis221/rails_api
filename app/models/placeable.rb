# == Schema Information
#
# Table name: placeables
#
#  id             :integer          not null, primary key
#  place_id       :integer
#  placeable_id   :integer
#  placeable_type :string(255)
#

class Placeable < ActiveRecord::Base
  belongs_to :place
  belongs_to :placeable, polymorphic: true

  delegate :company_id, to: :placeable

  after_create :update_area_denominators
  before_destroy :update_area_denominators

  protected
    def update_area_denominators
      if placeable.is_a?(Area)
        placeable.send(:update_common_denominators)
        placeable.campaign_ids.each do |id|
          Rails.cache.delete("campaign_locations_#{id}")
        end
      end
    end
end
