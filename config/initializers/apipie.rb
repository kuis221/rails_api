Apipie.configure do |config|
  config.app_name                = 'Brandscopic'
  config.api_base_url            = ''
  config.doc_base_url            = '/apidoc'
  # were is your API defined?
  config.api_controllers_matcher = "#{Rails.root}/app/controllers/api/v1/**/*.rb"

  config.authenticate = proc do
    authenticate_or_request_with_http_basic do |username, password|
      username == 'brandscopic' && password == 'BSP1k2014'
    end
  end

  config.app_info = <<-EOS
  == User Authentication
  Use the method sessions#create to authenticate a user and get the authorization key.

  For those methods that require an authenticated user, you must provide the
  user's email and authentication token in the headers as:
  +X-Auth-Token+ and +X-User-Email+, otherwise, you will receive a response code 401 from the server.
  Most of the methods require also the +X-Company-Id+ header to be present. This should reflect
  the company where the user is currently working.
  EOS
end
