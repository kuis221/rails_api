class ApplicationController < ActionController::Base
  protect_from_forgery

  include DatatablesHelper
  include SentientController
  include CurrentCompanyHelper

  before_filter :authenticate_user!
  before_filter :set_user_company
  after_filter :update_user_last_activity

  layout :set_layout

  helper_method :current_company

  protected
    def set_layout
      user_signed_in? ? 'application' : 'empty'
    end

    def current_company
      @current_company ||= begin
        current_company_id = session[:current_company_id]
        if current_company_id
          current_user.companies.find(current_company_id)
        else
          current_user.companies.first
        end
      end
    end

    def update_user_last_activity
      current_user.update_column(:last_activity_at, DateTime.now) if user_signed_in? && request.format.html?
    end

    def set_user_company
      current_user.current_company = current_company if user_signed_in?
    end

    # Overwriting the sign_out redirect path method
    def after_sign_out_path_for(resource_or_scope)
      new_user_session_path
    end
end
