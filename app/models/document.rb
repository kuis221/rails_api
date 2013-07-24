# == Schema Information
#
# Table name: documents
#
#  id            :integer          not null, primary key
#  name          :string(255)
#  created_by_id :integer
#  updated_by_id :integer
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  event_id      :integer
#

class Document < ActiveRecord::Base
  track_who_does_it

  belongs_to :event
  has_one :attached_asset, :as => :attachable

  accepts_nested_attributes_for :attached_asset
  attr_accessible :name, :attached_asset_attributes

  delegate :file_file_name, :download_url, :file_extension, to: :attached_asset

  validates :name, presence: true
end
