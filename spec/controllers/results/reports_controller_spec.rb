require 'spec_helper'

describe Results::ReportsController do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  let(:report){ FactoryGirl.create(:report, company: @company) }

  describe "GET 'index'" do
    it "returns http success" do
      report.reload
      get 'index'
      response.should be_success
      expect(assigns(:reports)).to match_array [report]
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', format: :js
      response.should be_success
      response.should render_template('new')
      response.should render_template('_form')
    end
  end

  describe "GET 'preview'" do
    let(:report) { FactoryGirl.create(:report, company: @company) }
    it "returns http success" do
      get 'preview', id: report.id, format: :js
      response.should be_success
      response.should render_template('preview')
      response.should render_template('_report_preview')

      expect(assigns(:report)).to be_new_record
    end
  end

  describe "GET 'show'" do
    it "assigns the loads the correct objects and templates" do
      get 'show', id: report.id
      expect(assigns(:report)).to eql report
      expect(response).to render_template(:show)
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', format: :js
      response.should be_success
    end

    it "should not render form_dialog if no errors" do
      expect {
        post 'create', report: {name: 'Test report', description: 'Test report description'}, format: :js
      }.to change(Report, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).to_not render_template('_form_dialog')

      report = Report.last
      expect(report.name).to eql 'Test report'
      expect(report.description).to eql 'Test report description'
    end

    it "should render the form_dialog template if errors" do
      expect {
        post 'create', format: :js
      }.to_not change(Report, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      expect(assigns(:report).errors.count).to be > 0
    end
  end

  describe "GET 'deactivate'" do
    it "deactivates an active report" do
      report.update_attribute(:active, true)
      get 'deactivate', id: report.to_param, format: :js
      response.should be_success
      report.reload.active?.should be_false
    end

    it "activates an inactive report" do
      report.update_attribute(:active, false)
      get 'activate', id: report.to_param, format: :js
      response.should be_success
      report.reload.active?.should be_true
    end
  end

  describe "PUT 'update'" do
    it "must update the report attributes" do
      put 'update', id: report.to_param, report: {name: 'Test Report', description: 'Test Report description'}
      assigns(:report).should == report
      response.should redirect_to([:results, report])
      report.reload
      report.name.should == 'Test Report'
      report.description.should == 'Test Report description'
    end

    it "must update the report fields attributes" do
      put 'update', id: report.to_param, report: {
        rows:    [{field: 'place:name', label: 'Venue Name', aggregate: 'sum', precision: '4'}],
        columns: [{field: 'place:name', label: 'Venue Name'}],
        values:  [{field: 'kpi:1', label: 'Impressions', aggregate: 'sum', precision: '1'}],
        filters:  [{field: 'place:name', label: 'Place'}]
      }, format: :js
      assigns(:report).should == report
      expect(response).to render_template('update')
      report.reload
      expect(report.rows.map{|r| {field: r.field, label: r.label, aggregate: r.aggregate, precision: r.precision}}).to eql [{field: 'place:name', label: 'Venue Name', aggregate: 'sum', precision: 4}]
      expect(report.columns.map{|r| {field: r.field, label: r.label}}).to eql [{field: 'place:name', label: 'Venue Name'}]
      expect(report.values.map{|r| {field: r.field, label: r.label, aggregate: r.aggregate, precision: r.precision}}).to eql [{field: 'kpi:1', label: 'Impressions', aggregate: 'sum', precision: 1}]
    end

    it "must update the sharing attributes" do
      put 'update', id: report.to_param, report: {sharing: 'everyone'}, format: :js
      expect(assigns(:report)).to eql report
      expect(response).to render_template('update')
      report.reload
      expect(report.sharing).to eql 'everyone'
    end

    it "store the report sharing associations" do
      user = FactoryGirl.create(:company_user, company: @company)
      team = FactoryGirl.create(:team, company: @company)
      role = FactoryGirl.create(:role, company: @company)
      expect {
        put 'update', id: report.to_param, report: {
          sharing: 'custom',
          sharing_selections: ["company_user:#{user.id}", "team:#{team.id}", "role:#{role.id}"]}, format: :js
      }.to change(ReportSharing, :count).by(3)

      expect(assigns(:report)).to eql report
      expect(response).to render_template('update')
      report.reload
      expect(report.sharing).to eql 'custom'
      expect(report.sharing_selections).to eql ["company_user:#{user.id}", "team:#{team.id}", "role:#{role.id}"]
      expect(report.sharings.map(&:shared_with)).to match_array [user, team, role]
    end
  end
end
