require 's3_direct_upload'

ActionView::Base.send(:include, S3DirectUpload::UploadHelper) if defined?(ActionView::Base)

S3DirectUpload.config do |c|
  c.access_key_id     = ENV['AWS_ACCESS_KEY_ID']
  c.secret_access_key = ENV['AWS_SECRET_ACCESS_KEY']
  c.bucket            = ENV['S3_BUCKET_NAME']
  c.region            = 's3'
end
