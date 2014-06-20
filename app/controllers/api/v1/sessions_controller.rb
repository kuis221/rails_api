class Api::V1::SessionsController < Api::V1::ApiController
  skip_before_filter :verify_authenticity_token
  skip_before_filter :set_user

  skip_authorize_resource
  skip_authorization_check

  resource_description do
    short 'Site members'
    formats ['json', 'xml']
    error 404, "Missing"
    error 401, "Invalid credentials"
    error 500, "Server crashed for some reason"
    description <<-EOS
      == Token Authentication

    EOS
  end


  api :POST, '/api/v1/sessions', 'Authenticate a user and return the authentication token'
  param :email, String, required: true, desc: "User's email"
  param :password, String, required: true, desc: "User's password"
  formats ['json', 'xml']
  description <<-EOS
  Validates the user credentials and returns the authentication token if valid.
  EOS
  example <<-EOS
  POST /api/v1/sessions.json?email=fulano@detal.com&password=MySuperSecretPassword
  {
    sucess: true,
    info: 'Logged in',
    data: {
      auth_token: 'XXXYYYYZZZ',
      current_company_id: 1
    }
  }
  EOS
  def create
    resource = User.find_for_database_authentication(:email=>params[:email])

    if resource && resource.valid_password?(params[:password])
      resource.ensure_authentication_token
      resource.current_company = resource.companies.first if resource.current_company.nil? || !resource.companies.include?(resource.current_company)
      resource.save :validate => false
      sign_in(:user, resource)
      render :status => 200,
             :json => { :success => true,
                        :info => "Logged in",
                        :data => { :auth_token => resource.authentication_token, current_company_id: resource.current_company_id } }

    else
      render :status => 401,
       :json => { :success => false,
                  :info => "Login Failed",
                  :data => {} }
    end

  end

  api :DELETE, '/api/v1/sessions', 'Destroy authentication token for a user'
  param :id, String, required: true, desc: "Authentication token"
  def destroy
    resource = User.find_by_authentication_token(params[:id])
    if resource.nil?
      render :status=>404, :json=>{sucess: false, info: 'Invalid token.'}
    else
      resource.reset_authentication_token!

      render :status=>200, :json=>{success: true, info: 'Logged out' + resource.errors.inspect, token: params[:id]}
    end
  end
end