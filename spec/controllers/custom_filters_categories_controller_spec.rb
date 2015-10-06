require 'rails_helper'

describe CustomFiltersCategoriesController, type: :controller do
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
    it 'creates a custom filter category for the company' do
      expect do
        xhr :post, 'create', custom_filters_category: { name: 'My Custom Filter Category' }, format: :js
      end.to change(CustomFiltersCategory, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template('create')
      expect(response).not_to render_template('_form_dialog')
      custom_filters_category = CustomFiltersCategory.last
      expect(custom_filters_category.name).to eq('My Custom Filter Category')
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', custom_filters_category: { name: '' }, format: :js
      end.not_to change(CustomFiltersCategory, :count)
      expect(response).to render_template('create')
      expect(response).to render_template('_form_dialog')
      assigns(:custom_filters_category).errors.count > 0
    end
  end
end
