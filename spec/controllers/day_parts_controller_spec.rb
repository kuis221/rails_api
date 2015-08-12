require 'rails_helper'

describe DayPartsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_success
    end

    describe 'json requests' do
      it 'responds to .json format' do
        get 'index', format: :json
        expect(response).to be_success
      end
    end

    it 'queue the job for export the list to CSV' do
      expect do
        xhr :get, :index, format: :csv
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      expect(export.controller).to eql('DayPartsController')
      expect(export.export_format).to eql('csv')
    end

    it 'queue the job for export the list to PDF' do
      expect do
        xhr :get, :index, format: :pdf
      end.to change(ListExport, :count).by(1)
      export = ListExport.last
      expect(ListExportWorker).to have_queued(export.id)
      expect(export.controller).to eql('DayPartsController')
      expect(export.export_format).to eql('pdf')
    end
  end

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'edit'" do
    let(:day_part) { create(:day_part, company: @company) }
    it 'returns http success' do
      xhr :get, 'edit', id: day_part.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'show'" do
    let(:day_part) { create(:day_part, company: @company) }
    it 'assigns the loads the correct objects and templates' do
      get 'show', id: day_part.id
      expect(assigns(:day_part)).to eq(day_part)
      expect(response).to render_template(:show)
    end
  end

  describe "POST 'create'" do
    it 'returns http success' do
      xhr :post, 'create', format: :js
      expect(response).to be_success
    end

    it 'should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', day_part: { name: 'Test day part', description: 'Test day part description' }, format: :js
      end.to change(DayPart, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')

      day_part = DayPart.last
      expect(day_part.name).to eq('Test day part')
      expect(day_part.description).to eq('Test day part description')
      expect(day_part.active).to be_truthy
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', format: :js
      end.not_to change(DayPart, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:day_part).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:day_part) { create(:day_part, company: @company) }

    it 'deactivates an active day_part' do
      day_part.update_attribute(:active, true)
      xhr :get, 'deactivate', id: day_part.to_param, format: :js
      expect(response).to be_success
      expect(day_part.reload.active?).to be_falsey
    end

    it 'activates an inactive day_part' do
      day_part.update_attribute(:active, false)
      xhr :get, 'activate', id: day_part.to_param, format: :js
      expect(response).to be_success
      expect(day_part.reload.active?).to be_truthy
    end
  end

  describe "PUT 'update'" do
    let(:day_part) { create(:day_part, company: @company) }

    it 'must update the day_part attributes' do
      t = create(:day_part, company: @company)
      put 'update', id: day_part.to_param, day_part: { name: 'Test day part update', description: 'Test day part description update' }
      expect(assigns(:day_part)).to eq(day_part)
      expect(response).to redirect_to(day_part_path(day_part))
      day_part.reload
      expect(day_part.name).to eq('Test day part update')
      expect(day_part.description).to eq('Test day part description update')
    end
  end

  describe "GET 'list_export'", search: true do
    it 'should return an empty book with the correct headers' do
      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION', 'ACTIVE STATE']
      ])
    end

    it 'should include the results' do
      create(:day_part, company: @company,
             name: 'Morningns', description: 'From 8 to 11am', active: true)
      Sunspot.commit

      expect { xhr :get, 'index', format: :csv }.to change(ListExport, :count).by(1)
      expect(ListExportWorker).to have_queued(ListExport.last.id)
      ResqueSpec.perform_all(:export)
      expect(ListExport.last).to have_rows([
        ['NAME', 'DESCRIPTION', 'ACTIVE STATE'],
        ['Morningns', 'From 8 to 11am', 'Active']
      ])
    end
  end
end
