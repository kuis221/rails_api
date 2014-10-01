require 'rails_helper'

describe BrandsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
  end

  describe 'campaign scope' do
    let(:campaign) { create(:campaign, company: @company) }

    describe "GET 'new'" do
      it 'returns http success' do
        get 'index', campaign_id: campaign.to_param, format: :json
        expect(response).to be_success
      end
    end
  end

  describe 'brand portfolio scope' do
    let(:brand_portfolio) { create(:brand_portfolio, company: @company) }

    describe "GET 'new'" do
      it 'returns http success' do
        xhr :get, 'new', brand_portfolio_id: brand_portfolio.to_param, format: :js
        expect(response).to be_success
        expect(response).to render_template('new')
        expect(response).to render_template('_form')
      end
    end

    describe "POST 'create'" do
      it 'should assign the new brand to the brand portfolio' do
        expect do
          expect do
            xhr :post, 'create', brand_portfolio_id: brand_portfolio.to_param, brand: { name: 'Test Brand', marques_list: 'Marque 1' }, format: :js
          end.to change(Brand, :count).by(1)
        end.to change(brand_portfolio.brands, :count).by(1)
      end
    end
  end

  describe "GET 'edit'" do
    let(:brand) { create(:brand, company: @company) }
    it 'returns http success' do
      xhr :get, 'edit', id: brand.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'items'" do
    it 'returns the correct structure' do
      get 'items'
      expect(response).to be_success
    end
  end

  describe "GET 'show'" do
    let(:brand) { create(:brand, company: @company) }
    it 'assigns the loads the correct objects and templates' do
      get 'show', id: brand.id
      expect(assigns(:brand)).to eq(brand)
      expect(response).to render_template(:show)
    end
  end

  describe "GET 'index'", search: true do
    let(:campaign) { create(:campaign, company: @company) }
    let(:brand_portfolio) { create(:brand_portfolio, company: @company) }
    it 'returns the brands associated to a campaign' do
      campaign.brands << create(:brand, name: 'Brand 123', company: @company)
      campaign.brands << create(:brand, name: 'Brand 456', company: @company)
      brand_portfolio.brands << create(:brand, name: 'Brand 871', company: @company)
      create(:brand, name: 'Brand 789', company: @company)
      Sunspot.commit
      get 'index', campaign_id: campaign.id, format: :json

      expect(response).to be_success
      parsed_body = JSON.parse(response.body)
      expect(parsed_body.count).to eq(2)
      expect(parsed_body.map { |b| b['name'] }).to eq(['Brand 456', 'Brand 123'])
    end

    it 'returns the brands associated to a brand portfolio' do
      brand_portfolio.brands << create(:brand, name: 'Brand 123', company: @company)
      brand_portfolio.brands << create(:brand, name: 'Brand 456', company: @company)
      campaign.brands << create(:brand, name: 'Brand 871', company: @company)
      create(:brand, name: 'Brand 789', company: @company)
      Sunspot.commit
      get 'index', brand_portfolio_id: brand_portfolio.id, format: :json

      expect(response).to be_success
      parsed_body = JSON.parse(response.body)
      expect(parsed_body.count).to eq(2)
      expect(parsed_body.map { |b| b['name'] }).to eq(['Brand 456', 'Brand 123'])
    end
  end

  describe "GET 'deactivate'" do
    let(:brand) { create(:brand, company: @company) }

    it 'deactivates an active brand' do
      brand.update_attribute(:active, true)
      xhr :get, 'deactivate', id: brand.to_param, format: :js
      expect(response).to be_success
      expect(brand.reload.active?).to be_falsey
    end

    it 'activates an inactive brand' do
      brand.update_attribute(:active, false)
      xhr :get, 'activate', id: brand.to_param, format: :js
      expect(response).to be_success
      expect(brand.reload.active?).to be_truthy
    end
  end

  describe "POST 'create'" do
    it 'returns http success' do
      xhr :post, 'create', format: :js
      expect(response).to be_success
    end

    it 'should not render form_dialog if no errors' do
      expect do
        xhr :post, 'create', brand: { name: 'Test Brand', marques_list: 'Marque 1,Marque 2' }, format: :js
      end.to change(Brand, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')

      brand = Brand.last
      expect(brand.name).to eq('Test Brand')
      expect(brand.marques.all.map(&:name)).to match_array(['Marque 1', 'Marque 2'])
    end

    it 'should render the form_dialog template if errors' do
      expect do
        xhr :post, 'create', format: :js
      end.not_to change(Brand, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      expect(assigns(:brand).errors.count).to be > 0
    end
  end

  describe "PUT 'update'" do
    let(:brand) { create(:brand, company: @company) }
    it 'must update the brand attributes' do
      put 'update', id: brand.to_param, brand: { name: 'Test brand', marques_list: 'Marque 1' }
      expect(assigns(:brand)).to eq(brand)
      brand.reload
      expect(brand.name).to eq('Test brand')
      expect(brand.marques.all.map(&:name)).to match_array(['Marque 1'])
    end
  end
end
