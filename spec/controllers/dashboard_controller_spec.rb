require 'rails_helper'

describe DashboardController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
    Kpi.create_global_kpis
  end

  it 'should render all modules' do
    get 'index'
    expect(response).to be_success
    expect(response).to render_template('_incomplete_tasks')
    expect(response).to render_template('_kpi_trends')
    expect(response).to render_template('_upcoming_events')
    expect(response).to render_template('_recent_photos')
    expect(response).to render_template('_recent_comments')
    expect(response).to render_template('_venue_performance')
    expect(response).to render_template('_campaign_overview')
  end
end
