class Api::V1::ApiController < ActionController::Base
  respond_to :json, :xml

  include SentientController

  rescue_from 'Api::V1::InvalidAuthToken', with: :invalid_token
  rescue_from 'Api::V1::InvalidCompany', with: :invalid_company
  rescue_from 'ActiveRecord::RecordNotFound', with: :record_not_found

  before_filter :set_user
  after_filter :set_access_control_headers


  protected
    def current_company
      @current_company ||= current_company_user.company
    end

    def current_company_user
      @current_company_user ||= current_user.company_users.where(company_id: params[:company_id]).first if current_user.present?
      raise Api::V1::InvalidCompany.new(params[:company_id]) if @current_company_user.nil? || !@current_company_user.active?

      @current_company_user
    end

    def current_user
      unless params[:auth_token].nil? || params[:auth_token].strip == ''
        @current_user ||= User.find_by_authentication_token(params[:auth_token]) or raise Api::V1::InvalidAuthToken.new(params[:auth_token]), "invalid token"
      end
    end

    def invalid_token
      respond_to do |format|
        format.json {
          render :status => 401,
                 :json => { :success => false,
                            :info => "Invalid auth token",
                            :data => {} }
        }
        format.xml {
          render :status => 401,
                 :xml => { :success => false,
                           :info => "Invalid auth token",
                           :data => {} }.to_xml(root: 'response')
        }
      end
    end


    def invalid_company
      respond_to do |format|
        format.json {
          render :status => 401,
                 :json => { :success => false,
                            :info => "Invalid company",
                            :data => {} }
        }
        format.xml {
          render :status => 401,
                 :xml => { :success => false,
                           :info => "Invalid company",
                           :data => {} }.to_xml(root: 'response')
        }
      end
    end

    def record_not_found
      respond_to do |format|
        format.json {
          render :status => 404,
                 :json => { :success => false,
                            :info => "Record not found",
                            :data => {} }
        }
        format.xml {
          render :status => 404,
                 :xml => { :success => false,
                           :info => "Record not found",
                           :data => {} }.to_xml(root: 'response')
        }
      end
    end

    def set_user
      User.current = current_user
      User.current.current_company = current_company if params.has_key?(:company_id)
    end

    def set_access_control_headers
      unless Rails.env.production?
        headers['Access-Control-Allow-Origin'] = '*'
      else
        headers['Access-Control-Allow-Origin'] = '*.brandscopic.com'
      end
      headers['Access-Control-Request-Method'] = '*'
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