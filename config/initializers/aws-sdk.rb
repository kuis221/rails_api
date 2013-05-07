 S3_CONFIGS = YAML::load(ERB.new(IO.read("#{Rails.root}/config/amazon_s3.yml")).result)[Rails.env]
 AWS.config(S3_CONFIGS)

 PAPERCLIP_SETTINGS = {
  :s3_credentials => {
    :access_key_id =>  S3_CONFIGS['access_key_id'],
    :secret_code => S3_CONFIGS['secret_access_ke']
  },
  :bucket => S3_CONFIGS['bucket_name'],
  :storage => :s3
 }