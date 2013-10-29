class Api::V1::SessionsController < Api::V1::ApiController
  skip_before_filter :verify_authenticity_token

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


  api :POST, '/api/v1/sessions'
  param :email, String, required: true, desc: "User's email"
  param :password, String, required: true, desc: "User's password"
  formats ['json', 'xml']
  def create
    resource = User.find_for_database_authentication(:email=>params[:email])

    if resource && resource.valid_password?(params[:password])
      resource.ensure_authentication_token
      resource.save :validate => false
      sign_in(:user, resource)
      render :status => 200,
             :json => { :success => true,
                        :info => "Logged in",
                        :data => { :auth_token => resource.authentication_token } }

    else
      render :status => 401,
       :json => { :success => false,
                  :info => "Login Failed",
                  :data => {} }
    end

  end

  api :DELETE, '/api/v1/sessions'
  param :id, String, required: true, desc: "Authentication token"
  def destroy
    resource = User.find_by_authentication_token(params[:id])
    if resource.nil?
      render :status=>404, :json=>{sucess: false, info: 'Invalid token.'}
    else
      resource.reset_authentication_token!
      render :status=>200, :json=>{success: true, info: 'Logged out', token: params[:id]}
    end
  end
end