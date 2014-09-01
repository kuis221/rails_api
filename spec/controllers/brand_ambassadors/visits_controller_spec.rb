require 'rails_helper'

RSpec.describe BrandAmbassadors::VisitsController, :type => :controller do

  let(:company){ FactoryGirl.create(:company) }
  let(:user){ FactoryGirl.create(:company_user, company: company) }

  before{ sign_in_as_user user }

  describe "GET 'edit'" do
    let(:visit){ FactoryGirl.create(:brand_ambassadors_visit, company: company) }
    it "returns http success" do
      xhr :get, 'edit', id: visit.to_param, format: :js
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

  describe "POST 'create'" do
    it "should successfully create the new record" do
      expect {
        xhr :post, 'create', brand_ambassadors_visit: {name: 'Test Visit', company_user_id: user.id, start_date: '01/23/2014', end_date: '01/24/2014'}, format: :js
      }.to change(BrandAmbassadors::Visit, :count).by(1)
      visit = BrandAmbassadors::Visit.last
      expect(visit.name).to eq('Test Visit')
      expect(visit.company_user_id).to eq(user.id)
      expect(visit.company_id).to eq(company.id)
      expect(visit.active).to eq(true)

      expect(response).to render_template(:create)
      expect(response).not_to render_template('_form_dialog')
    end

    it "should render the form_dialog template if errors" do
      expect {
        xhr :post, 'create', format: :js
      }.not_to change(BrandAmbassadors::Visit, :count)
      expect(response).to render_template(:create)
      expect(response).to render_template('_form_dialog')
      assigns(:visit).errors.count > 0
    end
  end

  describe "GET 'deactivate'" do
    let(:visit){ FactoryGirl.create(:brand_ambassadors_visit, company: company) }

    it "deactivates an active visit" do
      visit.update_attribute(:active, true)
      xhr :get, 'deactivate', id: visit.to_param, format: :js
      expect(response).to be_success
      expect(visit.reload.active?).to be_falsey
    end
  end

  describe "GET 'activate'" do
    let(:visit){ FactoryGirl.create(:brand_ambassadors_visit, company: company, active: false) }

    it "activates an inactive `visit" do
      expect(visit.active?).to be_falsey
      xhr :get, 'activate', id: visit.to_param, format: :js
      expect(response).to be_success
      expect(visit.reload.active?).to be_truthy
    end
  end

  describe "PUT 'update'" do
    let(:visit){ FactoryGirl.create(:brand_ambassadors_visit, company: company) }

    it "must update the visit attributes" do
      put 'update', id: visit.to_param, brand_ambassadors_visit: {name: 'New Visit Name', company_user_id: user.id, start_date: '01/23/2014', end_date: '01/24/2014'}
      expect(assigns(:visit)).to eq(visit)
      expect(response).to redirect_to(brand_ambassadors_visit_path(visit))
      visit.reload
      expect(visit.name).to eq('New Visit Name')
      expect(visit.start_date).to eql Date.new(2014, 01, 23)
      expect(visit.end_date).to eql Date.new(2014, 01, 24)
    end
  end

end
