Apipie.configure do |config|
  config.app_name                = "Brandscopic"
  config.api_base_url            = ""
  config.doc_base_url            = "/apipie"
  # were is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/v1/*.rb"


  config.authenticate = Proc.new do
    authenticate_or_request_with_http_basic do |username, password|
      username == "brandscopic" && password == "BSP1k2014"
    end
  end
end
