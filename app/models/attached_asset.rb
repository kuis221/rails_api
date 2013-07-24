# == Schema Information
#
# Table name: attached_assets
#
#  id                :integer          not null, primary key
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  asset_type        :string(255)
#  attachable_id     :integer
#  attachable_type   :string(255)
#  created_by_id     :integer
#  updated_by_id     :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

class AttachedAsset < ActiveRecord::Base
  track_who_does_it

  belongs_to :attachable, :polymorphic => true
  has_attached_file :file, PAPERCLIP_SETTINGS
  attr_accessible :file, :asset_type

  validates_attachment_presence :file

  def file_extension(filename)
    File.extname(filename)[1..-1]
  end

  def download_url(style_name=:original)
    s3 = AWS::S3.new
    @bucket ||= s3.buckets[file.bucket_name]
    @bucket.objects[file.s3_object(style_name).key].url_for(:read,
      :secure => true,
      :expires => 24*3600, # 24 hours
      :response_content_disposition => "attachment; filename='#{file_file_name}'").to_s
  end
end
