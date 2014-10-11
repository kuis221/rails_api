# == Schema Information
#
# Table name: areas_campaigns
#
#  id          :integer          not null, primary key
#  area_id     :integer
#  campaign_id :integer
#  exclusions  :integer          default([]), is an Array
#  inclusions  :integer          default([]), is an Array
#

class AreasCampaign < ActiveRecord::Base
  belongs_to :area
  belongs_to :campaign

  attr_accessor :reference

  def self.find_by_area_id!(area_id)
    find_by!(area_id: area_id)
  end

  # If place is in /North America/United States/California/Los Angeles and the area
  # includes Los Angeles or any parent (like California)
  def place_in_scope?(place)
    if place.present?
      @place_ids ||= area.place_ids
      return true if place.persisted? && (@place_ids - exclusions + inclusions).include?(place.id)
      political_location = Place.political_division(place).join('/').downcase
      locations.any? { |location| political_location.include?(location.path) }
    else
      false
    end
  end

  def locations
    @locations ||= Rails.cache.fetch("area_campaign_locations_#{area_id}_#{campaign.id}") do
      Location.joins('INNER JOIN places ON places.location_id=locations.id')
        .where(places: { id: area.place_ids + inclusions, is_location: true })
        .where.not(places: { id: exclusions + [0] })
        .group('locations.id')
    end
  end

  def places
    (area.places + Place.where(id: inclusions)).sort_by{|p| p.name}
  end

  def place_reference(value)
    place = if value && value.present?
              if value =~ /^[0-9]+$/
                Place.find(value)
              else
                reference, place_id = value.split('||')
                Place.find_or_create_by(place_id: place_id) do |p|
                  p.reference = reference
                end
              end
            end
    place
  end
end
