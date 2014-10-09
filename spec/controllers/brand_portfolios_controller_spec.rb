require 'rails_helper'

describe BrandPortfoliosController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  describe "GET 'edit'" do
    let(:brand_portfolio) { create(:brand_portfolio, company: @company) }
    it 'returns http success' do
      xhr :get, 'edit', id: brand_portfolio.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'index'" do
    it 'returns http success' do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "GET 'new'" do
    it 'returns http success' do
      xhr :get, 'new', format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'items'" do
    it 'returns the correct structure' do
      get 'items'
      expect(response).to be_success
    end
  end

  describe "GET 'select_brands'" do
    let(:brand_portfolio) { create(:brand_portfolio, company: @company) }
    it 'returns http success' do
      xhr :get, 'select_brands', id: brand_portfolio.to_param, format: :js
      expect(response).to be_success
      expect(assigns(:brand_portfolio)).to eq(brand_portfolio)
    end
  end

  describe "POST 'add_brands'" do
    let(:brand_portfolio) { create(:brand_portfolio, company: @company) }
    it 'should add the brand to the portfolio' do
      brand = create(:brand, company: @company)
      expect do
        xhr :post, 'add_brands', id: brand_portfolio.to_param, brand_id: brand.to_param, format: :js
      end.to change(BrandPortfoliosBrand, :count).by(1)
      expect(response).to be_success
      expect(assigns(:brand_portfolio)).to eq(brand_portfolio)
      expect(brand_portfolio.brands).to eq([brand])
    end

    it 'should not add duplicated brands to portfolios' do
      brand = create(:brand, company: @company)
      brand_portfolio.brands << brand
      expect do
        xhr :post, 'add_brands', id: brand_portfolio.to_param, brand_id: brand.to_param, format: :js
      end.to_not change(BrandPortfoliosBrand, :count)
      expect(response).to be_success
      expect(assigns(:brand_portfolio)).to eq(brand_portfolio)
      expect(brand_portfolio.reload.brands).to eq([brand])
    end
  end

  describe "DELETE 'delete_brand'" do
    let(:brand_portfolio) { create(:brand_portfolio, company: @company) }
    it 'should delete the brand from the portfolio' do
      brand = create(:brand)
      brand_portfolio.brands << brand
      expect do
        expect do
          delete 'delete_brand', id: brand_portfolio.to_param, brand_id: brand.to_param, format: :js
        end.to_not change(Brand, :count)
        expect(response).to be_success
      end.to change(brand_portfolio.brands, :count).by(-1)
    end
  end

  describe "GET 'show'" do
    let(:brand_portfolio) { create(:brand_portfolio, company: @company) }
    it 'assigns the loads the correct objects and templates' do
      get 'show', id: brand_portfolio.id
      expect(assigns(:brand_portfolio)).to eq(brand_portfolio)
      expect(response).to render_template(:show)
    end
  end

  describe "POST 'create'" do
    it 'should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', brand_portfolio: { name: 'Test brand portfolio', description: 'Test brand portfolio description' }, format: :js
      end.to change(BrandPortfolio, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')

      portfolio = BrandPortfolio.last
      expect(portfolio.name).to eq('Test brand portfolio')
      expect(portfolio.description).to eq('Test brand portfolio description')
      expect(portfolio.active).to be_truthy
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', format: :js
      end.not_to change(BrandPortfolio, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:brand_portfolio).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:brand_portfolio) { create(:brand_portfolio, company: @company) }

    it 'deactivates an active brand_portfolio' do
      brand_portfolio.update_attribute(:active, true)
      xhr :get, 'deactivate', id: brand_portfolio.to_param, format: :js
      expect(response).to be_success
      expect(brand_portfolio.reload.active?).to be_falsey
    end

    it 'activates an inactive brand_portfolio' do
      brand_portfolio.update_attribute(:active, false)
      xhr :get, 'activate', id: brand_portfolio.to_param, format: :js
      expect(response).to be_success
      expect(brand_portfolio.reload.active?).to be_truthy
    end
  end

  describe "PUT 'update'" do
    let(:brand_portfolio) { create(:brand_portfolio, company: @company) }
    it 'must update the brand_portfolio attributes' do
      t = create(:brand_portfolio)
      put 'update', id: brand_portfolio.to_param, brand_portfolio: { name: 'Test brand_portfolio', description: 'Test brand_portfolio description' }
      expect(assigns(:brand_portfolio)).to eq(brand_portfolio)
      expect(response).to redirect_to(brand_portfolio_path(brand_portfolio))
      brand_portfolio.reload
      expect(brand_portfolio.name).to eq('Test brand_portfolio')
      expect(brand_portfolio.description).to eq('Test brand_portfolio description')
    end
  end

end
