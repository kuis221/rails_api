require 'rails_helper'

describe Analysis::StaffReportController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'index'" do
    it 'should load all the current campaign ' do
      users = [@company_user]
      users.push create(:company_user, company_id: @company.id, role: @company_user.role)
      users.push create(:company_user, company_id: @company.id, role: @company_user.role)

      get 'index'

      expect(response).to be_success
      expect(assigns(:users)).to match_array(users)
    end
  end

  describe "GET 'index'" do

    it 'should render the user report' do
      xhr :get, 'report', report: { user_id: @company_user.to_param }, format: :js
      expect(response).to be_success
    end

    it 'should assign the correct scope to @events_scope' do
      company_user = create(:company_user, company_id: @company.id)
      events = create_list(:approved_event, 3, company: @company, user_ids: [company_user.id])
      create(:event, company: @company) # Unapproved event
      create(:approved_event, company: @company)
      without_current_user { create(:approved_event, company_id: @company.id + 1) }

      xhr :get, 'report', report: { user_id: company_user.to_param }, format: :js

      expect(response).to be_success
      expect(assigns(:events_scope)).to match_array(events)
    end

    it "should load all the campaign's goals into @goals" do
      Kpi.create_global_kpis
      goals = [
        create(:goal, goalable: @company_user, kpi_id: Kpi.impressions.id),
        create(:goal, goalable: @company_user, kpi_id: Kpi.events.id),
        create(:goal, goalable: @company_user, kpi_id: Kpi.interactions.id)
      ]

      xhr :get, 'report', report: { user_id: @company_user.to_param }, format: :js

      expect(response).to be_success
      expect(assigns(:goals)).to match_array(goals)
    end

    it 'should render the report partials' do
      Kpi.create_global_kpis
      events = create_list(:approved_event, 3, company: @company, user_ids: [@company_user.id])

      goals = [
        create(:goal, goalable: @company_user, kpi_id: Kpi.impressions.id),
        create(:goal, goalable: @company_user, kpi_id: Kpi.events.id),
        create(:goal, goalable: @company_user, kpi_id: Kpi.interactions.id)
      ]

      xhr :get, 'report', report: { user_id: @company_user.to_param }, format: :js

      expect(response).to be_success
      expect(response).to render_template('_report_section_events')
      expect(response).to render_template('_report_section_promo_hours')
      expect(response).to render_template('_report_section_objectives')
    end

  end

end
