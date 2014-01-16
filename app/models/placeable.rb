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

  after_create :update_associated_resources
  before_destroy :update_associated_resources

  def update_associated_resources
    if placeable.is_a?(Area)
      placeable.send(:update_common_denominators)
      Rails.cache.delete("area_locations_#{placeable.id}")
      placeable.campaign_ids.each do |id|
        Rails.cache.delete("campaign_locations_#{id}")
      end
    elsif placeable.is_a?(Campaign)
      Rails.cache.delete("campaign_locations_#{placeable.id}")
    end
  end
end
