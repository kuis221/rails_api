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
  attr_accessible :content

  validates :content, presence: true
  validates :created_by_id, presence: true, numericality: true

end
