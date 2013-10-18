class Api::V1::SessionsController < Api::V1::ApiController
  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }



  resource_description do
    short 'Site members'
    formats ['json', 'xml']
    param :id, Fixnum, :desc => "User ID", :required => false
    param :resource_param, Hash, :desc => 'Param description for all methods' do
      param :ausername, String, :desc => "Username for login", :required => true
      param :apassword, String, :desc => "Password for login", :required => true
    end
    error 404, "Missing"
    error 500, "Server crashed for some <%= reason %>"
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
      sign_in(:user, resource)
      render :status => 200,
             :json => { :success => true,
                        :info => "Logged in",
                        :data => { :auth_token => resource.authentication_token } }

    else
      failure
    end

  end

  api :DELETE, '/api/v1/sessions'
  def destroy
    warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
    current_user.update_column(:authentication_token, nil)
    render :status => 200,
           :json => { :success => true,
                      :info => "Logged out",
                      :data => {} }
  end

  def failure
    render :status => 401,
           :json => { :success => false,
                      :info => "Login Failed",
                      :data => {} }
  end
end