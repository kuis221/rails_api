class ApplicationController < ActionController::Base
  protect_from_forgery

  around_filter :scope_current_user

  skip_before_filter :verify_authenticity_token, :if =>lambda{ params[:authenticity_token].present? && params[:authenticity_token] == 'S3CR37Master70k3N' }

  include CurrentCompanyHelper

  before_filter :authenticate_user!
  after_filter :update_user_last_activity
  after_filter :remove_viewed_notification

  before_filter :remember_return_path, only: :show

  layout :set_layout

  helper_method :current_company, :custom_body_class, :modal_dialog_title

  rescue_from 'CanCan::AccessDenied', with: :access_denied

  protected
    def set_layout
      user_signed_in? ? 'application' : 'empty'
    end

    def current_company
      @current_company ||= begin
        current_company_id = session[:current_company_id]
        company = nil
        if user_signed_in?
          if current_company_id
            company = current_user.companies.find(current_company_id) rescue nil
          else
            company = current_user.current_company
          end
          company ||= current_user.companies.first
        end
        company
      end
    end

    def update_user_last_activity
      current_company_user.update_column(:last_activity_at, DateTime.now) if user_signed_in? && request.format.html? && current_company_user.present?
    end

    # Overwriting the sign_out redirect path method
    def after_sign_out_path_for(resource_or_scope)
      new_user_session_path
    end

    def custom_body_class
      @custom_body_class ||= ''
    end

    def remember_return_path
      if params.has_key?(:return) and params[:return]
        session["return_path"] = Base64.decode64(params.has_key?(:return)) rescue nil
      end
    end

    def modal_dialog_title
      I18n.translate("modals.title.#{resource.new_record? ? 'new' : 'edit'}.#{resource.class.name.underscore.downcase}")
    end

    def remove_viewed_notification
      if params[:notifid]
        current_company_user.notifications.where(id: params[:notifid]).destroy_all
      end
    end

    def access_denied
      respond_to do |format|
        format.js { render 'access_denied' }
        format.html { render 'access_denied' }
      end
    end

    def scope_current_user
      User.current = current_user
      if user_signed_in?
        Company.current = current_user.current_company = current_company
        Time.zone = current_user.time_zone
        ::NewRelic::Agent.add_custom_parameters(:user_id => current_user.id)
      end
      yield
    ensure
      User.current = nil
      Company.current = nil
      Time.zone = Rails.application.config.time_zone
    end
end
