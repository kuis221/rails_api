 AWS.config({use_ssl: true })

 PAPERCLIP_SETTINGS = {
  :s3_credentials => {
    :access_key_id =>  ENV['AWS_ACCESS_KEY_ID'],
    :secret_code => ENV['AWS_SECRET_ACCESS_KEY']
  },
  :bucket => ENV['S3_BUCKET_NAME'],
  :storage => :s3
 }