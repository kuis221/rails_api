# == Schema Information
#
# Table name: asset_downloads
#
#  id                :integer          not null, primary key
#  uid               :string(255)
#  assets_ids        :text
#  aasm_state        :string(255)
#  file_file_name    :string(255)
#  file_content_type :string(255)
#  file_file_size    :integer
#  file_updated_at   :datetime
#  user_id           :integer
#  last_downloaded   :datetime
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#

require 'zip'

class AssetDownload < ActiveRecord::Base
  belongs_to :user

  validates :uid, presence: true

  serialize :assets_ids

  has_attached_file :file, PAPERCLIP_SETTINGS

  do_not_validate_attachment_file_type :file

  include AASM

  aasm do
    state :new, :initial => true
    state :queued, before_enter: :queue_process
    state :processing, after_enter: :compress_assets
    state :completed

    event :queue do
      transitions :from => [:new, :complete], :to => :queued
    end

    event :process do
      transitions :from => [:queued, :new], :to => :processing
    end

    event :complete do
      transitions :from => :processing, :to => :completed
    end
  end

  def queue_process
    Resque.enqueue(AssetsDownloadWorker, self.id)
  end

  def self.find_or_create_by_assets_ids(ids, params)
    uid = Digest::MD5.hexdigest(ids.join(','))
    find_or_create_by_uid(uid, params)
  end

  def download_url(style_name=:original)
    file.s3_bucket.objects[file.s3_object(style_name).key].url_for(:read,
      :secure => true,
      :expires => 24*3600, # 24 hours
      :response_content_disposition => "attachment; filename=#{file_file_name}").to_s
  end

  def compress_assets
    tmp_filename = "#{Rails.root}/tmp/assets-#{uid}.zip"
    File.delete(tmp_filename) if File.exists?(tmp_filename) # Make sure the zipfile doesn't exists

    # Add all the assets to the zip file
    Zip::File.open(tmp_filename, Zip::File::CREATE) do |zip|
      #get all of the attachments
      AttachedAsset.find(assets_ids).each do |a|
        photo_local_name = "#{Rails.root}/tmp/#{a.id}"
        a.file.copy_to_local_file(:original, photo_local_name)

        # Check if the file was downloaded successfully and add it to the zip
        zip.add(a.file.original_filename, photo_local_name) if File.exists?(photo_local_name)
      end
    end
    self.file = File.open(tmp_filename)

    begin
      save
    rescue AWS::S3::Errors::RequestTimeout
      save # Try again
    end

    File.delete(tmp_filename)

    # Mark download as completed
    self.complete!
  end
end
