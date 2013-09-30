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
end
