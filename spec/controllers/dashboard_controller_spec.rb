require 'spec_helper'

describe DashboardController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
    Kpi.create_global_kpis
  end

  it "should render all modules" do
    get 'index'
    response.should be_success
    response.should render_template('demographics')
    response.should render_template('incomplete_tasks')
    response.should render_template('kpi_trends')
    response.should render_template('upcomming_events')
    response.should render_template('venue_performance')
  end

  it "should render all modules" do
    get 'index'
    response.should be_success
    response.should render_template('demographics')
    response.should render_template('incomplete_tasks')
    response.should render_template('kpi_trends')
    response.should render_template('upcomming_events')
    response.should render_template('venue_performance')
  end
end