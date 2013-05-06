# == Schema Information
#
# Table name: tasks
#
#  id         :integer          not null, primary key
#  event_id   :integer
#  title      :string(255)
#  due_at     :datetime
#  user_id    :integer
#  completed  :boolean
#  created_at :datetime         not null
#  updated_at :datetime         not null
#

class Task < ActiveRecord::Base
  belongs_to :event
  belongs_to :user
  attr_accessible :completed, :due_at, :title, :user_id

  delegate :full_name, to: :user, prefix: true, allow_nil: true

  validates :title, presence: true
  validates :user_id, numericality: true, if: :user_id
  validates :event_id, presence: true, numericality: true
end
