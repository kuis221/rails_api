class Comment < ActiveRecord::Base
  track_who_does_it

  belongs_to :commentable, :polymorphic => true
  attr_accessible :content

  validates :content, presence: true
  validates :created_by_id, presence: true, numericality: true

end
