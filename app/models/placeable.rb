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
      Area.update_common_denominators(placeable)
    elsif placeable.is_a?(CompanyUser)
      Rails.cache.delete("user_accessible_locations_#{placeable.id}")
      Rails.cache.delete("user_accessible_places_#{placeable.id}")
    elsif placeable.is_a?(Campaign)
      Rails.cache.delete("campaign_locations_#{placeable.id}")
    end
  end
end
