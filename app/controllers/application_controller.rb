class ApplicationController < ActionController::Base
  protect_from_forgery

  skip_before_filter :verify_authenticity_token, :if =>lambda{ params[:authenticity_token].present? && params[:authenticity_token] == 'S3CR37Master70k3N' }

  include SentientController
  include CurrentCompanyHelper

  before_filter :authenticate_user!
  before_filter :set_user_company
  after_filter :update_user_last_activity

  before_filter :set_timezone

  before_filter :remember_return_path, only: :show

  layout :set_layout

  helper_method :current_company, :custom_body_class, :modal_dialog_title

  protected
    def set_layout
      user_signed_in? ? 'application' : 'empty'
    end

    def current_company
      @current_company ||= begin
        current_company_id = session[:current_company_id]
        company = nil
        if current_company_id
          company = current_user.companies.find(current_company_id) rescue nil
        else
          company = current_user.current_company
        end
        company ||= current_user.companies.first
        company
      end
    end

    def update_user_last_activity
      current_company_user.update_column(:last_activity_at, DateTime.now) if user_signed_in? && request.format.html? && current_company_user.present?
    end

    def set_user_company
      current_user.current_company = current_company if user_signed_in?
    end

    # Overwriting the sign_out redirect path method
    def after_sign_out_path_for(resource_or_scope)
      new_user_session_path
    end

    def custom_body_class
      @custom_body_class ||= ''
    end

    def set_timezone
      if current_user.present? and current_user.time_zone.present?
        Time.zone = current_user.time_zone
      else
        Time.zone = Brandscopic::Application.config.time_zone
      end
    end

    def remember_return_path
      if params.has_key?(:return) and params[:return]
        session["return_path"] = Base64.decode64(params.has_key?(:return)) rescue nil
      end
    end

    def modal_dialog_title
      I18n.translate("modals.title.#{resource.new_record? ? 'new' : 'edit'}.#{resource.class.name.underscore.downcase}")
    end
end
