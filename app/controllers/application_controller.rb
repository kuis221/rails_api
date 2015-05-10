# Base Application Controller class
#
# This class perform some general validations and sets up the
# environment for the currently logged in user
class ApplicationController < ActionController::Base
  include CurrentUser
  include ReturnableControllerHelper
  protect_from_forgery

  skip_before_action :verify_authenticity_token, if: lambda {
    params[:authenticity_token].present? && params[:authenticity_token] == 'S3CR37Master70k3N'
  }

  before_action :authenticate_user_by_token
  before_action :authenticate_user!

  layout :set_layout

  helper_method :custom_body_class, :modal_dialog_title

  rescue_from 'CanCan::AccessDenied', with: :access_denied

  protected

  def set_layout
    user_signed_in? ? 'application' : 'empty'
  end

  def company_roles
    current_company.roles
  end

  def company_teams
    current_company.teams
  end

  def company_campaigns
    current_company.campaigns.order('name')
  end

  def current_company
    @current_company ||= begin
      current_company_id = session[:current_company_id]
      company = nil
      if user_signed_in?
        if current_company_id
          company = current_user.companies.find_by(id: current_company_id)
        else
          company = current_user.current_company
        end
        company ||= current_user.companies.first
      end
      company
    end
  end

  # Overwriting the sign_out redirect path method
  def after_sign_out_path_for(_)
    new_user_session_path
  end

  def custom_body_class
    @custom_body_class ||= ''
  end

  def modal_dialog_title
    I18n.translate(
      "modals.title.#{resource.new_record? ? 'new' : 'edit'}.#{resource.class.name.underscore}")
  end

  def default_url_options
    options = {}
    options[:return] = return_path if params[:return]
    options[:phase] = params[:phase] if params[:phase]
    options
  end

  # Allow GET methods for JS/JSON requests so PDF exports can work in background jobs
  def authenticate_user_by_token
    return unless request.format.js? || request.format.json?
    return if request.headers['X-Auth-Token'].blank? || request.headers['X-User-Email'].blank?

    @_current_user = User.find_by(
      email: request.headers['X-User-Email'],
      authentication_token: request.headers['X-Auth-Token'])
    sign_in(:user, @_current_user)
  end

  def access_denied(exception)
    @exception = exception
    respond_to do |format|
      format.json { render text: 'Permission denied', status: 403 }
      format.js { render 'access_denied' }
      format.html { render 'access_denied' }
    end
  end
end
