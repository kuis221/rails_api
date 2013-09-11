class Analysis::StaffReportController < ApplicationController
  before_filter :company_user, only: :report
  authorize_resource :campaign, only: :report

  def index
    @users = current_company.company_users.joins(:user).accessible_by(current_ability).order('users.first_name ASC')
  end

  def report
  end

  private
    def company_user
      @company_user ||= current_company.company_users.find(params[:report][:user_id])
    end
end