class Placeable < ActiveRecord::Base
  belongs_to :place
  belongs_to :placeable, polymorphic: true
end
