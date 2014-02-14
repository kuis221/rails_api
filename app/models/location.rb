class Location < ActiveRecord::Base
  attr_accessible :path

  has_and_belongs_to_many :places
end
