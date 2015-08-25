require 'rails_helper'

describe AreasController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }
  let(:campaign) { create(:campaign, company: company) }

  before { user }

  let(:area) { create(:area, company: company) }

  describe "GET 'edit'" do
    it 'returns http success' do
      xhr :get, 'edit', id: area.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_success
    end

    it 'queue the job for export the list to CSV' do
      expect do
        xhr :get, :index, format: :csv
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      expect(export.controller).to eql('AreasController')
      expect(export.export_format).to eql('csv')
    end

    it 'queue the job for export the list to PDF' do
      expect do
        xhr :get, :index, format: :pdf
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      expect(export.controller).to eql('AreasController')
      expect(export.export_format).to eql('pdf')
    end
  end

  describe "GET 'items'" do
    it 'returns http success' do
      get 'items'
      expect(response).to be_success
    end
  end

  describe "GET 'cities'" do
    it 'assigns the loads the correct objects and templates' do
      expect_any_instance_of(Area).to receive(:cities).and_return([double(name: 'My Cool City')])
      get 'cities', id: area.id, format: :json
      expect(assigns(:area)).to eq(area)
      cities = JSON.parse(response.body)
      expect(cities).to eql ['My Cool City']
    end
  end

  describe "GET 'show'" do
    it 'assigns the loads the correct objects and templates' do
      get 'show', id: area.id
      expect(assigns(:area)).to eq(area)
      expect(response).to render_template(:show)
    end
  end

  describe "POST 'create'" do
    it 'does not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', area: { name: 'Test Area', description: 'Test Area description' }, format: :js
      end.to change(Area, :count).by(1)
      area = Area.last
      expect(area.name).to eq('Test Area')
      expect(area.description).to eq('Test Area description')
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')
    end

    it 'renders the form_dialog template if errors' do
      expect do
        xhr :post, 'create', format: :js
      end.not_to change(Area, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:area).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    it 'deactivates an active area' do
      area.update_attribute(:active, true)
      xhr :get, 'deactivate', id: area.to_param, format: :js
      expect(response).to be_success
      expect(area.reload.active?).to be_falsey
    end

    it 'activates an inactive area' do
      area.update_attribute(:active, false)
      xhr :get, 'activate', id: area.to_param, format: :js
      expect(response).to be_success
      expect(area.reload.active?).to be_truthy
    end
  end

  describe "PUT 'update'" do
    it 'must update the area attributes' do
      put 'update', id: area.to_param, area: { name: 'Test Area', description: 'Test Area description' }
      expect(assigns(:area)).to eq(area)
      expect(response).to redirect_to(area_path(area))
      area.reload
      expect(area.name).to eq('Test Area')
      expect(area.description).to eq('Test Area description')
    end
  end

  describe "GET 'list_export'", search: true do
    it 'returns an empty book with the correct headers' do
      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION', 'ACTIVE STATE']
      ])
    end

    it 'includes the results' do
      create(:area, name: 'Gran Area Metropolitana',
                    description: 'Ciudades principales de Costa Rica',
                    active: true, company: company)
      Sunspot.commit

      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      expect(ListExportWorker).to have_queued(ListExport.last.id)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION', 'ACTIVE STATE'],
        ['Gran Area Metropolitana', 'Ciudades principales de Costa Rica', 'Active']
      ])
    end
  end

  describe "GET 'select_form'" do
    it 'includes all the active areas' do
      area = create(:area, company: company)
      create(:area, company: company, active: false) # Inactive area

      xhr :get, :select_form, campaign_id: campaign.id, format: :js

      expect(response).to be_success

      expect(assigns(:assignable_areas)).to eq([area])
    end

    it 'do not include the areas that belongs to the campaign' do
      area = create(:area, company: company)
      campaign.areas << create(:area, company: company)
      xhr :get, :select_form, campaign_id: campaign.id, format: :js

      expect(response).to be_success

      expect(assigns(:assignable_areas)).to eq([area])
    end

    it 'do not include the areas that belongs to the company user' do
      area = create(:area, company: company)
      company_user.areas << create(:area, company: company)
      xhr :get, :select_form, company_user_id: company_user.id, format: :js

      expect(response).to be_success

      expect(assigns(:assignable_areas)).to eq([area])
    end
  end

  describe "POST 'assign'" do
    let(:area) { create(:area, company: company) }
    it 'adds the area to the campaign' do
      expect do
        xhr :post, 'assign', campaign_id: campaign.id, id: area.id, format: :js
      end.to change(campaign.areas, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('areas/assign')
    end

    it 'adds the area to the company user' do
      expect(Rails.cache).to receive(:delete).with("user_accessible_locations_#{company_user.id}")
      expect(Rails.cache).to receive(:delete).with("user_accessible_places_#{company_user.id}")
      expect do
        xhr :post, 'assign', company_user_id: company_user.id, id: area.id, format: :js
      end.to change(company_user.areas, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('areas/assign')
      expect(response).to render_template('company_users/_areas_and_places')
      expect(response).to render_template('company_users/_areas')
    end
  end

  describe "DELETE 'unassign'" do
    let(:area) { create(:area, company: company) }
    let(:kpi) { create(:kpi, company: company) }

    it 'removes the area and the goals for the associated kpis from the campaign' do
      campaign.areas << area

      area_goal = area.goals.for_kpi(kpi)
      area_goal.parent = campaign
      area_goal.value = 100
      area_goal.save

      expect do
        expect do
          delete 'unassign', campaign_id: campaign.id, id: area.id, format: :js
        end.to change(campaign.areas, :count).by(-1)
      end.to change(Goal, :count).by(-1)

      expect(response).to be_success
      expect(response).to render_template('areas/unassign')
    end

    it 'removes the area from the company user' do
      company_user.areas << area

      area_goal = area.goals.for_kpi(kpi)
      area_goal.parent = company_user
      area_goal.value = 100
      area_goal.save

      expect(Rails.cache).to receive(:delete).with("user_accessible_locations_#{company_user.id}")
      expect(Rails.cache).to receive(:delete).with("user_accessible_places_#{company_user.id}")
      expect do
        expect do
          delete 'unassign', company_user_id: company_user.id, id: area.id, format: :js
        end.to change(company_user.areas, :count).by(-1)
      end.to change(Goal, :count).by(-1)
      expect(response).to be_success
      expect(response).to render_template('areas/unassign')
    end
  end
end
