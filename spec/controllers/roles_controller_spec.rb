require 'rails_helper'

describe RolesController, :type => :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  describe "GET 'edit'" do
    let(:role){ FactoryGirl.create(:role, company: @company) }
    it "returns http success" do
      xhr :get, 'edit', id: role.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      xhr :get, 'new', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end
  end

  describe "GET 'items'" do
    it "responds to .json format" do
      get 'items'
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it "should successfully create the new record" do
      expect {
        xhr :post, 'create', role: {name: 'Test Role', description: 'Test Role description'}, format: :js
      }.to change(Role, :count).by(1)
      role = Role.last
      expect(role.name).to eq('Test Role')
      expect(role.description).to eq('Test Role description')
      expect(role.active).to eq(true)

      expect(response).to render_template(:create)
    end

    it "should not render form_dialog if no errors" do
      expect {
        xhr :post, 'create', role: {name: 'Test Role', description: 'Test Role description'}, format: :js
      }.to change(Role, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')
    end

    it "should render the form_dialog template if errors" do
      expect {
        xhr :post, 'create', format: :js
      }.not_to change(Role, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:role).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:role){ FactoryGirl.create(:role, company: @company) }

    it "deactivates an active role" do
      role.update_attribute(:active, true)
      xhr :get, 'deactivate', id: role.to_param, format: :js
      expect(response).to be_success
      expect(role.reload.active?).to be_falsey
    end
  end

  describe "GET 'activate'" do
    let(:role){ FactoryGirl.create(:role, company: @company, active: false) }

    it "activates an inactive `role" do
      expect(role.active?).to be_falsey
      xhr :get, 'activate', id: role.to_param, format: :js
      expect(response).to be_success
      expect(role.reload.active?).to be_truthy
    end
  end

  describe "PUT 'update'" do
    let(:role){ FactoryGirl.create(:role, company: @company) }

    it "must update the role attributes" do
      put 'update', id: role.to_param, role: {name: 'New Role Name', description: 'New description for Role'}
      expect(assigns(:role)).to eq(role)
      expect(response).to redirect_to(role_path(role))
      role.reload
      expect(role.name).to eq('New Role Name')
      expect(role.description).to eq('New description for Role')
    end

    it "must update the role permissions, inserting them when they are selected" do
      expect {
        put 'update', id: role.to_param,
                      role: {permissions_attributes: [{enabled: "1", action: 'kpi_trends_module', subject_class: 'Symbol', subject_id: 'dashboard'},
                                                      {enabled: "1", action: 'upcomings_events_module', subject_class: 'Symbol', subject_id: 'dashboard'},
                                                      {enabled: "1", action: 'demographics_module', subject_class: 'Symbol', subject_id: 'dashboard'}
                                                     ]},
                      partial: "dashboard_permissions",
                      format: :js
      }.to change(role.permissions, :count).by(3)
      expect(response).to render_template('update_partial')
    end

    it "must update the role permissions, deleting them when enabled = 0" do
      permission1 = FactoryGirl.create(:permission, role_id: role.id, action: 'kpi_trends_module', subject_class: 'Symbol', subject_id: 'dashboard')
      permission2 = FactoryGirl.create(:permission, role_id: role.id, action: 'upcomings_events_module', subject_class: 'Symbol', subject_id: 'dashboard')
      permission3 = FactoryGirl.create(:permission, role_id: role.id, action: 'demographics_module', subject_class: 'Symbol', subject_id: 'dashboard')
      expect {
        xhr :put, 'update', id: role.to_param, role: {permissions_attributes: [{enabled: '0', id: permission1.id}, {enabled: '0', id: permission2.id}, {enabled: '0', id: permission3.id}]}, partial: "dashboard_permissions", format: :js
      }.to change(role.permissions, :count).by(-3)
      expect(response).to render_template('update_partial')
    end
  end
end
