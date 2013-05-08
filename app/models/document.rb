# == Schema Information
#
# Table name: documents
#
#  id                :integer          not null, primary key
#  name              :string(255)
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  documentable_id   :integer
#  documentable_type :string(255)
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class Document < ActiveRecord::Base
  belongs_to :documentable, :polymorphic => true
  has_attached_file :file, PAPERCLIP_SETTINGS
  attr_accessible :name, :file

  track_who_does_it

  validates :name, presence: true

  validates_attachment_presence :file

  def download_url(style_name=:original)
    s3 = AWS::S3.new
    @bucket ||= s3.buckets[file.bucket_name]
    @bucket.objects[file.s3_object(style_name).key].url_for(:read,
      :secure => true,
      :expires => 24*3600, # 24 hours
      :response_content_disposition => "attachment; filename='#{file_file_name}'").to_s
  end
end
