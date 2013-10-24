class Api::V1::UsersController < Api::V1::ApiController

  skip_before_filter :verify_authenticity_token,
                     :if => Proc.new { |c| c.request.format == 'application/json' }

  api :POST, '/api/v1/users/new_password'
  param :email, String, required: true, desc: "User's email"
  formats ['json', 'xml']
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