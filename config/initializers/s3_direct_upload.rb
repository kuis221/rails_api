S3DirectUpload.config do |c|
  c.access_key_id     = S3_CONFIGS['access_key_id']
  c.secret_access_key = S3_CONFIGS['secret_access_key']
  c.bucket            = S3_CONFIGS['bucket_name']
  c.region            = "s3"
end
