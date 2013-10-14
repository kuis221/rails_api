class Analysis::StaffReportController < ApplicationController
  before_filter :company_user, except: :index

  before_filter :authorize_actions

  def index
    @users = current_company.company_users.joins(:user).order('users.first_name ASC')
  end

  def report
    authorize! :show, company_user
    @events_scope = Event.with_user_in_team(company_user).where(aasm_state: 'approved')
    @goals = company_user.goals.base.includes(:kpi).where('goals.value is not null').all
  end

  private
    def company_user
      @company_user ||= current_company.company_users.find(params[:report][:user_id])
    end

    def authorize_actions
      authorize! :show_analysis, CompanyUser
    end
end