require 'active_support/concern'

module CurrentUser
  extend ActiveSupport::Concern

  included do
    around_filter :scope_current_user
    after_filter :update_user_last_activity
    helper_method :current_company, :current_company_user, :current_real_company_user,
                  :behave_as_user, :current_real_user
  end

  def current_company
    @current_company ||= current_company_user.company if user_signed_in?
  end

  def company_users
    current_company.company_users
  end

  def current_company_user
    @current_company_user ||=
      if behave_as_user.present?
        current_user.company_users.find_by!(company: current_real_company_user.company_id)
      else
        current_user.current_company_user || current_user.company_users.first
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

  def update_user_last_activity
    return unless user_signed_in? && request.format.html? && current_real_company_user.present?
    current_real_company_user.update_column :last_activity_at, DateTime.now
  end

  def current_user
    @_current_user ||=  (behave_as_user || current_real_user)
  end

  def current_real_user
    warden.authenticate(scope: :user)
  end

  def current_real_company_user
    current_real_user.current_company_user if current_real_user.present?
  end

  def behave_as_user
    return unless session[:behave_as_user_id] && current_real_user.present? && current_real_company_user.is_admin?
    @behave_as_user ||= User.find(session[:behave_as_user_id])
    @behave_as_user.current_company = current_real_user.current_company
    @behave_as_user
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
