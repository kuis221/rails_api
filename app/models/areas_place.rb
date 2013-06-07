# == Schema Information
#
# Table name: areas_places
#
#  id       :integer          not null, primary key
#  area_id  :integer
#  place_id :integer
#

class AreasPlace < ActiveRecord::Base
  belongs_to :area
  belongs_to :place
end
