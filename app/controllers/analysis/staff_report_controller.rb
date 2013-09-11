class Analysis::StaffReportController < ApplicationController
  before_filter :company_user, except: :index
  authorize_resource :campaign, except: :index

  def index
    @users = current_company.company_users.joins(:user).order('users.first_name ASC')
  end

  def report
     @events_scope = Event.with_user_in_team(company_user).where(aasm_state: 'approved')
     @goals = company_user.goals.base.includes(:kpi).all
  end

  private
    def company_user
      @company_user ||= current_company.company_users.find(params[:report][:user_id])
    end
end