# == Schema Information
#
# Table name: teamings
#
#  id            :integer          not null, primary key
#  team_id       :integer
#  teamable_id   :integer
#  teamable_type :string(255)
#

class Teaming < ActiveRecord::Base
  belongs_to :team
  belongs_to :teamable, polymorphic: true


  after_create :update_tasks

  after_destroy :update_tasks

  def update_tasks
    if teamable_type == 'Event'
      Sunspot.index(teamable.tasks)
    end
  end
end
