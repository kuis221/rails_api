require 'rails_helper'

describe Admin::KpisController, :type => :controller do
  before do
    @user = FactoryGirl.create(:admin_user)
    sign_in @user
  end

  let(:kpi) { FactoryGirl.create(:kpi) }

  describe "GET 'index'" do
    it "returns http success" do
      get :index
      expect(response).to be_success
    end
  end

  describe "GET 'show'" do
    it "returns http success" do
      get 'show', id: kpi.to_param
      expect(response).to be_success
      expect(assigns(:kpi)).to eq(kpi)
    end
  end

  describe "POST 'batch_action/merge'" do
    it "should render the admin/kpis/batch_action" do
      kpi1 = FactoryGirl.create(:kpi)
      kpi2 = FactoryGirl.create(:kpi)
      post 'batch_action', batch_action: "merge", collection_selection_toggle_all: 'on', collection_selection: [kpi1.id, kpi2.id]
      expect(response).to be_success
      expect(response).to render_template('kpis/batch_action')
    end

    it "redirects to kpis with an error if no kpis where given" do
      post 'batch_action', batch_action: "merge", collection_selection_toggle_all: 'on', collection_selection: []
      expect(response).to redirect_to(admin_kpis_path)
      expect(flash[:alert]).to eq('Please select more than one KPI to merge')
    end

    it "redirects to kpis with an error if more than one global KPI was selected" do
      Kpi.create_global_kpis
      post 'batch_action', batch_action: "merge", collection_selection_toggle_all: 'on', collection_selection: [Kpi.impressions.id, Kpi.interactions.id]
      expect(response).to redirect_to(admin_kpis_path)
      expect(flash[:alert]).to eq('It\'s not possible to merge two Out-of-the-box KPIs')
    end

    it "redirects to kpis with an error if two the KPIs are from different companies" do
      kpi1 = FactoryGirl.create(:kpi, company_id: 1)
      kpi2 = FactoryGirl.create(:kpi, company_id: 2)
      post 'batch_action', batch_action: "merge", collection_selection_toggle_all: 'on', collection_selection: [kpi1.id, kpi2.id]
      expect(response).to redirect_to(admin_kpis_path)
      expect(flash[:alert]).to eq('Cannot merge KPIs of different companies')
    end

    it "allows to select one global KPI with a custom KPI" do
      Kpi.create_global_kpis
      kpi1 = FactoryGirl.create(:kpi)
      post 'batch_action', batch_action: "merge", collection_selection_toggle_all: 'on', collection_selection: [Kpi.impressions.id, kpi1.id]
      expect(response).to be_success
      expect(response).to render_template('kpis/batch_action')
    end

    it "merges the KPIs and returns to the list page" do
      kpi1 = FactoryGirl.create(:kpi, company_id: 1)
      kpi2 = FactoryGirl.create(:kpi, company_id: 1)
      campaign = FactoryGirl.create(:campaign, company_id: 1)
      campaign.add_kpi kpi1
      campaign.add_kpi kpi2

      options  = {'confirm' => 'Merge', 'master_kpi' => {campaign.to_param => kpi1.id.to_s, campaign.to_param => kpi2.id.to_s} }
      post 'batch_action', batch_action: "merge", collection_selection_toggle_all: 'on', collection_selection: [kpi1.id, kpi2.id], merge: options
      expect(response).to redirect_to(admin_kpis_path)
      expect(KpiMergeWorker).to have_queued([kpi1.id, kpi2.id], options)
      expect(flash[:notice]).to eq('A job have been queued to merge the KPIs. This can take up to 2 minutes depending of the number of events/campaigns those KPIs are used')
    end
  end
end