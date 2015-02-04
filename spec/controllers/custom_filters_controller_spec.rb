require 'rails_helper'

describe CustomFiltersController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.company_users.first
  end

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
    end
  end

  describe "POST 'create'" do
    it 'creates a custom filter for the current user' do
      expect do
        xhr :post, 'create', custom_filter: {
          name: 'My Custom Filter',
          apply_to: 'events',
          filters: 'Filters' }, format: :js
      end.to change(CustomFilter, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('create')
      expect(response).not_to render_template('_form_dialog')
      custom_filter = CustomFilter.last
      expect(custom_filter.owner).to eq(@company_user)
      expect(custom_filter.name).to eq('My Custom Filter')
      expect(custom_filter.apply_to).to eq('events')
      expect(custom_filter.filters).to eq('Filters')
      expect(custom_filter.category_id).to be_nil
    end

    it 'creates a custom filter for the company' do
      category = create(:custom_filters_category, company: @company)
      expect do
        xhr :post, 'create',
                   company_id: @company.id,
                   custom_filter: {
                     name: 'My Custom Filter',
                     category_id: category.id,
                     apply_to: 'events',
                     filters: 'Filters' },
                   format: :js
      end.to change(CustomFilter, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('create')
      expect(response).not_to render_template('_form_dialog')
      custom_filter = CustomFilter.last
      expect(custom_filter.owner).to eq(@company)
      expect(custom_filter.name).to eq('My Custom Filter')
      expect(custom_filter.apply_to).to eq('events')
      expect(custom_filter.filters).to eq('Filters')
      expect(custom_filter.category_id).to eq(category.id)
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', custom_filter: { name: '', apply_to: '', filters: '' }, format: :js
      end.not_to change(CustomFilter, :count)
      expect(response).to render_template('create')
      expect(response).to render_template('_form_dialog')
      assigns(:custom_filter).errors.count > 0
    end
  end

  describe "DELETE 'destroy'" do
    let(:custom_filter) { create(:custom_filter, owner: @company_user, name: 'My Custom Filter', apply_to: 'events', filters: 'Filters') }
    it 'should delete the custom filter' do
      custom_filter # Make sure record is created before the expect block
      expect do
        delete 'destroy', id: custom_filter.to_param, format: :js
        expect(response).to be_success
        expect(response).to render_template(:destroy)
      end.to change(CustomFilter, :count).by(-1)
    end
  end

  describe "PUT 'default_view'" do
    let(:custom_filter) { create(:custom_filter, default_view: false, owner: @company_user, apply_to: 'events') }
    it 'returns http success' do
      custom_filter2 = create(:custom_filter, default_view: true, owner: @company_user, apply_to: 'events')
      xhr :put, 'default_view', id: custom_filter.to_param, format: :json
      expect(response).to be_success
      custom_filter.reload
      custom_filter2.reload
      expect(custom_filter.default_view).to be_truthy
      expect(custom_filter2.default_view).to be_falsey
    end
  end
end
