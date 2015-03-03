require 'rails_helper'

describe RolesController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  describe "GET 'edit'" do
    let(:role) { create(:role, company: @company) }
    it 'returns http success' do
      xhr :get, 'edit', id: role.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_success
    end

    it 'queue the job for export the list to XLS' do
      expect do
        xhr :get, :index, format: :xls
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      expect(export.controller).to eql('RolesController')
      expect(export.export_format).to eql('xls')
    end

    it 'queue the job for export the list to PDF' do
      expect do
        xhr :get, :index, format: :pdf
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      expect(export.controller).to eql('RolesController')
      expect(export.export_format).to eql('pdf')
    end
  end

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
      expect(response).to render_template('new')
      expect(response).to render_template('_form')
    end
  end

  describe "GET 'items'" do
    it 'responds to .json format' do
      get 'items'
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it 'should successfully create the new record' do
      expect do
        xhr :post, 'create', role: { name: 'Test Role', description: 'Test Role description' }, format: :js
      end.to change(Role, :count).by(1)
      role = Role.last
      expect(role.name).to eq('Test Role')
      expect(role.description).to eq('Test Role description')
      expect(role.active).to eq(true)

      expect(response).to render_template(:create)
    end

    it 'should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', role: { name: 'Test Role', description: 'Test Role description' }, format: :js
      end.to change(Role, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', format: :js
      end.not_to change(Role, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:role).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:role) { create(:role, company: @company) }

    it 'deactivates an active role' do
      role.update_attribute(:active, true)
      xhr :get, 'deactivate', id: role.to_param, format: :js
      expect(response).to be_success
      expect(role.reload.active?).to be_falsey
    end
  end

  describe "GET 'activate'" do
    let(:role) { create(:role, company: @company, active: false) }

    it 'activates an inactive `role' do
      expect(role.active?).to be_falsey
      xhr :get, 'activate', id: role.to_param, format: :js
      expect(response).to be_success
      expect(role.reload.active?).to be_truthy
    end
  end

  describe "PUT 'update'" do
    let(:role) { create(:role, company: @company) }

    it 'must update the role attributes' do
      put 'update', id: role.to_param, role: { name: 'New Role Name', description: 'New description for Role' }
      expect(assigns(:role)).to eq(role)
      expect(response).to redirect_to(role_path(role))
      role.reload
      expect(role.name).to eq('New Role Name')
      expect(role.description).to eq('New description for Role')
    end

    it 'must update the role permissions, inserting them when they are selected' do
      expect do
        put 'update', id: role.to_param,
                      role: { permissions_attributes: [
                        { action: 'kpi_trends_module', subject_class: 'Symbol', subject_id: 'dashboard', mode: 'none' },
                        { action: 'upcomings_events_module', subject_class: 'Symbol', subject_id: 'dashboard', mode: 'all' },
                        { action: 'demographics_module', subject_class: 'Symbol', subject_id: 'dashboard', mode: 'campaigns' }
                      ]},
                      partial: 'dashboard_permissions',
                      format: :js
      end.to change(role.permissions, :count).by(3)
      expect(response).to render_template('update_partial')
    end

    it 'must update the role permissions' do
      permission1 = create(:permission, role_id: role.id, action: 'kpi_trends_module', subject_class: 'Symbol', subject_id: 'dashboard', mode: 'none')
      permission2 = create(:permission, role_id: role.id, action: 'upcomings_events_module', subject_class: 'Symbol', subject_id: 'dashboard', mode: 'none')
      permission3 = create(:permission, role_id: role.id, action: 'demographics_module', subject_class: 'Symbol', subject_id: 'dashboard', mode: 'none')
      expect do
        xhr :put, 'update', id: role.to_param,
                            role: { permissions_attributes: [
                              { mode: 'all', id: permission1.id },
                              { mode: 'all', id: permission2.id },
                              { mode: 'campaigns', id: permission3.id }] },
                            partial: 'dashboard_permissions', format: :js
      end.to_not change(role.permissions, :count)
      expect(permission1.reload.mode).to eql 'all'
      expect(permission2.reload.mode).to eql 'all'
      expect(permission3.reload.mode).to eql 'campaigns'
      expect(response).to render_template('update_partial')
    end
  end

  describe "GET 'list_export'", search: true do
    it 'should return a book with the correct headers and the admin user' do
      expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION', 'ACTIVE STATE'],
        ['Super Admin', nil, 'Active']
      ])
    end

    it 'should include the results' do
      create(:role, name: 'Costa Rica Role',
              description: 'El grupo de ticos', active: true, company: @company)
      Sunspot.commit

      expect { xhr :get, 'index', format: :xls }.to change(ListExport, :count).by(1)
      expect(ListExportWorker).to have_queued(ListExport.last.id)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION', 'ACTIVE STATE'],
        ['Costa Rica Role', 'El grupo de ticos', 'Active'],
        ['Super Admin', nil, 'Active']
      ])
    end
  end
end
