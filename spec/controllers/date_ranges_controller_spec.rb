require 'spec_helper'

describe DateRangesController, :type => :controller do
before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
  end

  describe "GET 'edit'" do
    let(:date_range){ FactoryGirl.create(:date_range, company: @company) }
    it "returns http success" do
      get 'edit', id: date_range.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'new'" do
    it "returns http success" do
      get 'new', format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'index'" do
    it "returns http success" do
      get 'index'
      expect(response).to be_success
    end

    describe "json requests" do
      it "responds to .json format" do
        get 'index', format: :json
        expect(response).to be_success
      end
    end
  end

  describe "GET 'show'" do
    let(:date_range){ FactoryGirl.create(:date_range, company: @company) }
    it "assigns the loads the correct objects and templates" do
      get 'show', id: date_range.id
      expect(assigns(:date_range)).to eq(date_range)
      expect(response).to render_template(:show)
    end
  end

  describe "POST 'create'" do
    it "returns http success" do
      post 'create', format: :js
      expect(response).to be_success
    end

    it "should not render form_dialog if no errors" do
      expect {
        post 'create', date_range: {name: 'Test date range', description: 'Test date range description'}, format: :js
      }.to change(DateRange, :count).by(1)
      expect(response).to be_success
      expect(response).to render_template(:create)
      expect(response).not_to render_template(:form_dialog)

      portfolio = DateRange.last
      expect(portfolio.name).to eq('Test date range')
      expect(portfolio.description).to eq('Test date range description')
      expect(portfolio.active).to be_truthy
    end

    it "should render the form_dialog template if errors" do
      expect {
        post 'create', format: :js
      }.not_to change(DateRange, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template(:form_dialog)
      assigns(:date_range).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:date_range){ FactoryGirl.create(:date_range, company: @company) }

    it "deactivates an active date_range" do
      date_range.update_attribute(:active, true)
      get 'deactivate', id: date_range.to_param, format: :js
      expect(response).to be_success
      expect(date_range.reload.active?).to be_falsey
    end

    it "activates an inactive date_range" do
      date_range.update_attribute(:active, false)
      get 'activate', id: date_range.to_param, format: :js
      expect(response).to be_success
      expect(date_range.reload.active?).to be_truthy
    end
  end

  describe "PUT 'update'" do
    let(:date_range){ FactoryGirl.create(:date_range, company: @company) }
    it "must update the date_range attributes" do
      t = FactoryGirl.create(:date_range, company: @company)
      put 'update', id: date_range.to_param, date_range: {name: 'Test date_range', description: 'Test date_range description'}
      expect(assigns(:date_range)).to eq(date_range)
      expect(response).to redirect_to(date_range_path(date_range))
      date_range.reload
      expect(date_range.name).to eq('Test date_range')
      expect(date_range.description).to eq('Test date_range description')
    end
  end


end
