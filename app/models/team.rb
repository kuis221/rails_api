class Team < ActiveRecord::Base
  attr_accessible :created_by_id, :description, :name, :updated_by_id
end
