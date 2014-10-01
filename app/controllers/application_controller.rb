# Base Application Controller class
#
# This class perform some general validations and sets up the
# environment for the currently logged in user
class ApplicationController < ActionController::Base
  protect_from_forgery

  around_filter :scope_current_user

  skip_before_action :verify_authenticity_token, if: lambda{
    params[:authenticity_token].present? && params[:authenticity_token] == 'S3CR37Master70k3N'
  }

  before_action :authenticate_user_by_token
  before_action :authenticate_user!
  after_filter :update_user_last_activity

  layout :set_layout

  helper_method :current_company, :custom_body_class, :modal_dialog_title

  rescue_from 'CanCan::AccessDenied', with: :access_denied

  protected

  def set_layout
    user_signed_in? ? 'application' : 'empty'
  end

  def company_users
    current_company.company_users
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

  def current_company_user
    current_user.current_company_user
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

  def update_user_last_activity
    return unless user_signed_in? && request.format.html? && current_company_user.present?

    current_company_user.update_column :last_activity_at, DateTime.now
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

  # Allow GET methods for JS/JSON requests so PDF exports can work in background jobs
  def authenticate_user_by_token
    return unless request.format.js? || request.format.json?
    return unless params[:auth_token].present? && !params[:auth_token].empty?

    @_current_user = User.find_by!(authentication_token: params[:auth_token])
    sign_in(:user, @_current_user)
    headers['Access-Control-Allow-Origin'] = '*'
  end

  def access_denied(exception)
    @exception = exception
    respond_to do |format|
      format.json { render text: 'Permission denied', status: 403 }
      format.js { render 'access_denied' }
      format.html { render 'access_denied' }
    end
  end

  def scope_current_user
    User.current = current_user
    set_user_settings if user_signed_in?
    yield
  ensure
    User.current = nil
    Company.current = nil
    Time.zone = Rails.application.config.time_zone
  end

  def set_new_relic_custom_params
    ::NewRelic::Agent.add_custom_parameters(user_id: current_user.id)
    ::NewRelic::Agent.add_custom_parameters(company_user_id: current_company_user.id)
    ::NewRelic::Agent.set_user_attributes(
      user: current_user.email,
      account: current_company.name
    )
  end

  def set_user_settings
    Company.current = current_company
    unless current_user.current_company_id == Company.current.id
      current_user.update_column :current_company_id, Company.current.id
      current_user.current_company = Company.current
    end
    Time.zone = current_user.time_zone
    set_new_relic_custom_params
  end
end
