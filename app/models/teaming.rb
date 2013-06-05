class Teaming < ActiveRecord::Base
  belongs_to :team
  belongs_to :teamable, polymorphic: true
end
