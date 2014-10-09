# == Schema Information
#
# Table name: receipts
#
#  id                :integer          not null, primary key
#  event_id          :integer
#  thumbnail         :string(255)
#  height            :integer
#  width             :integer
#  creator_id        :integer
#  updater_id        :integer
#  created_at        :datetime
#  updated_at        :datetime
#  parent_id         :integer
#  file_file_name    :string(255)
#  file_file_size    :integer
#  file_content_type :string(255)
#  file_updated_at   :datetime
#  file_processing   :boolean
#

class Legacy::Receipt < Legacy::Record
  belongs_to :event

  include Paperclip::Glue

  has_attached_file :file, {
    styles: { small: '100x100>' },
    url: '/receipts/:id/:basename:dashed_style.:extension', path: 'receipts/:id/:basename:dashed_style.:extension'
  }.merge(Legacy::PAPERCLIP_SETTINGS)
end
