# == Schema Information
#
# Table name: tasks
#
#  id            :integer          not null, primary key
#  event_id      :integer
#  title         :string(255)
#  due_at        :datetime
#  user_id       :integer
#  completed     :boolean
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  created_by_id :integer
#  updated_by_id :integer
#

class Task < ActiveRecord::Base
  track_who_does_it

  belongs_to :event
  belongs_to :user
  attr_accessible :completed, :due_at, :title, :user_id
  has_many :comments, :as => :commentable

  validates_datetime :due_at, allow_nil: true, allow_blank: true

  delegate :full_name, to: :user, prefix: true, allow_nil: true

  validates :title, presence: true
  validates :user_id, numericality: true, if: :user_id
  validates :event_id, presence: true, numericality: true
end
