class Api::V1::ApiController < ActionController::Base
  respond_to :json, :xml


  protected
    def current_company
      @current_company ||= current_user.company_users.where(company_id: params[company_id]).company if current_user && params[company_id]
    end

    def current_user
      @current_user ||= User.find_by_authentication_token(params[:auth_token])
    end
end