class Api::V1::UsersController < Api::V1::ApiController

  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  resource_description do
    short 'Users'
    formats ['json', 'xml']
    error 404, "Missing"
    error 500, "Server crashed for some reason"
    description <<-EOS

    EOS
  end

  api :POST, '/api/v1/users/new_password', 'Request a new password for a user'
  param :email, String, required: true, desc: "User's email"
  def new_password
    resource = User.send_reset_password_instructions(params)

    if resource.persisted?
      render :status => 200,
             :json => { :success => true,
                        :info => "Reset password instructions sent",
                        :data => {} }
    else
      failure
    end
  end

  def failure
    render :status => 401,
           :json => { :success => false,
                      :info => "Action Failed",
                      :data => {} }
  end
end