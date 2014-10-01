# == Schema Information
#
# Table name: photos
#
#  id                  :integer          not null, primary key
#  photographable_id   :integer
#  photographable_type :string(255)
#  height              :integer
#  width               :integer
#  parent_id           :integer
#  thumbnail           :string(255)
#  creator_id          :integer
#  updater_id          :integer
#  created_at          :datetime
#  updated_at          :datetime
#  active              :boolean          default(TRUE), not null
#  file_file_name      :string(255)
#  file_file_size      :integer
#  file_content_type   :string(255)
#  file_updated_at     :datetime
#  file_processing     :boolean
#

class Legacy::Photo < Legacy::Record
  include Paperclip::Glue

  has_many :data_migrations, as: :remote

  # Associations
  belongs_to :photographable, polymorphic: true

  has_attached_file :file, {
    url: '/photos/:id/:basename:dashed_style.:extension', path: 'photos/:id/:basename:dashed_style.:extension'
  }.merge(Legacy::PAPERCLIP_SETTINGS)
end
