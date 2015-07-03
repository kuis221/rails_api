class Api::V1::ApiController < ActionController::Base
  respond_to :json, :xml

  include SentientController

  rescue_from 'Api::V1::InvalidAuthToken', with: :invalid_token
  rescue_from 'Api::V1::InvalidCompany', with: :invalid_company
  rescue_from 'ActiveRecord::RecordNotFound', with: :record_not_found
  rescue_from 'Apipie::ParamInvalid', with: :invalid_argument
  rescue_from 'Apipie::ParamMissing', with: :invalid_argument
  rescue_from 'CanCan::AccessDenied', with: :access_denied

  before_action :ensure_valid_request
  after_action :set_access_control_headers
  after_action :update_user_last_activity_mobile

  around_filter :scope_current_user

  load_and_authorize_resource only: [:show, :edit, :update, :destroy, :new], unless: :skip_default_validation
  authorize_resource only: [:create, :index], unless: :skip_default_validation

  check_authorization

  def options
  end

  protected

  def current_company
    @current_company ||= current_company_user.company
  end

  def current_company_user
    @current_company_user ||= current_user.company_users.where(company_id: current_company_id).first if current_user.present?
    fail Api::V1::InvalidCompany.new(current_company_id) if @current_company_user.nil? || !@current_company_user.active?

    @current_company_user
  end

  def current_user
    token = request.headers['X-Auth-Token']
    email = request.headers['X-User-Email']
    return if token.nil? || token.strip == ''
    @current_user ||= User.where(email: email).find_by_authentication_token(token) or fail Api::V1::InvalidAuthToken.new(token), 'invalid token'
  end

  def current_company_id
    request.headers['X-Company-Id']
  end

  def access_denied
    respond_to do |format|
      format.json do
        render status: 403,
               json: { success: false,
                       info: 'Forbidden',
                       data: {} }
      end
    end
  end

  def invalid_token
    respond_to do |format|
      format.json do
        render status: 401,
               json: { success: false,
                       info: 'Invalid auth token',
                       data: {} }
      end
    end
  end

  def invalid_company
    respond_to do |format|
      format.json do
        render status: 401,
               json: { success: false,
                       info: 'Invalid company',
                       data: {} }
      end
    end
  end

  def record_not_found
    respond_to do |format|
      format.json do
        render status: 404,
               json: { success: false,
                       info: 'Record not found',
                       data: {} }
      end
    end
  end

  def set_access_control_headers
    if ENV['HEROKU_APP_NAME'] == 'brandscopic'
      headers['Access-Control-Allow-Origin'] = 'http://m.brandscopic.com'
    else
      headers['Access-Control-Allow-Origin'] = '*'
    end
    headers['Access-Control-Expose-Headers'] = 'ETag'
    headers['Access-Control-Allow-Methods'] = 'GET, POST, PUT, DELETE, OPTIONS, HEAD'
    headers['Access-Control-Allow-Headers'] = '*,x-requested-with,Content-Type,If-Modified-Since,If-None-Match,X-Auth-Token,X-User-Email,X-Company-Id'
    headers['Access-Control-Max-Age'] = '86400'
  end

  def update_user_last_activity_mobile
    @current_company_user.update_column(:last_activity_mobile_at, DateTime.now) if user_signed_in? && @current_company_user.present?
  end

  def ensure_valid_request
    return if %w(json xml).include?(params[:format]) || request.headers['Accept'] =~ /json|xml/
    render nothing: true, status: 406
  end

  def skip_default_validation
    false
  end

  def invalid_argument(exception)
    respond_to do |format|
      format.json do
        render status: 400,
               json: { success: false,
                       info: exception.message }
      end
    end
  end

  def jbb_feature_enabled?
    current_company.id == 2
  end

  def scope_current_user
    User.current = current_user
    if user_signed_in?
      User.current.current_company = current_company if current_company_id
      Time.zone = current_user.time_zone
      Company.current = current_company
    end
    yield
  ensure
    User.current = nil
    Company.current = nil
    Time.zone = Rails.application.config.time_zone
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
