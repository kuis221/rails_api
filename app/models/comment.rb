# == Schema Information
#
# Table name: comments
#
#  id               :integer          not null, primary key
#  commentable_id   :integer
#  commentable_type :string(255)
#  content          :text
#  created_by_id    :integer
#  updated_by_id    :integer
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#

class Comment < ActiveRecord::Base
  track_who_does_it

  belongs_to :commentable, :polymorphic => true
  belongs_to :user, :foreign_key => "created_by_id"

  delegate :full_name, to: :user, prefix: true, allow_nil: true

  attr_accessible :content

  validates :content, presence: true
  validates :commentable_id, presence: true, numericality: true
  validates :commentable_type, presence: true

  scope :for_places, lambda{|places| joins('INNER JOIN events e ON e.id = commentable_id and commentable_type=\'Event\'').where(['e.place_id in (?)', places]) }
end
