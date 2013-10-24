class Api::V1::ApiController < ActionController::Base
  respond_to :json, :xml

  rescue_from 'Api::V1::InvalidAuthToken', with: :invalid_token
  rescue_from 'Api::V1::InvalidCompany', with: :invalid_company


  protected
    def current_company
      @current_company ||= current_company_user.company
    end

    def current_company_user
      @current_company_user ||= current_user.company_users.where(company_id: params[:company_id]).first
      raise Api::V1::InvalidCompany.new(params[:company_id]) if @current_company_user.nil? || !@current_company_user.active?

      @current_company_user
    end

    def current_user
      @current_user ||= User.find_by_authentication_token(params[:auth_token]) or raise Api::V1::InvalidAuthToken.new(params[:auth_token]), "invalid token"
    end

    def invalid_token
      render :status => 401,
       :json => { :success => false,
                  :info => "Invalid auth token",
                  :data => {} }
    end


    def invalid_company
      render :status => 401,
       :json => { :success => false,
                  :info => "Invalid company",
                  :data => {} }
    end
end


class Api::V1::InvalidAuthToken < StandardError
  attr_reader :token

  def initialize(token)
    @token = token
  end
end


class Api::V1::InvalidCompany < StandardError
  attr_reader :id

  def initialize(id)
    @id = id
  end
end