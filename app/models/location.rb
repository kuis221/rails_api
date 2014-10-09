# == Schema Information
#
# Table name: locations
#
#  id   :integer          not null, primary key
#  path :string(500)
#

class Location < ActiveRecord::Base
  has_and_belongs_to_many :places
end
