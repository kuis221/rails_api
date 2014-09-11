require 'rails_helper'

describe Results::EventStatusController, :type => :controller do
  let(:user) { sign_in_as_user }
  let(:company_user) { user.current_company_user }
  let(:company) { user.companies.first }
  let(:campaign) { FactoryGirl.create(:campaign, company: company, name: 'Test Campaign FY01') }

  before { user }

  describe "GET 'index'" do
    it "should return http success" do
      get 'index'
      expect(response).to be_success
    end
  end

  describe "POST 'report'" do
    it "should call the promo_hours_graph_data method to get the overall data for the campaign" do
      expect(Campaign).to receive(:promo_hours_graph_data).and_return([])
      xhr :post, 'report', report: { campaign_id: campaign.id }, format: :js
      expect(response).to be_success
      expect(response).to render_template('results/event_status/report')
      expect(response).to render_template('results/event_status/_report')
    end

    it "should call the event_status_data_by_areas method to get the overall data for the campaign" do
      expect_any_instance_of(Campaign).to receive(:event_status_data_by_areas).with(company_user).and_return([])
      xhr :post, 'report', report: { campaign_id: campaign.id, group_by: 'place' }, format: :js
      expect(response).to be_success
      expect(response).to render_template('results/event_status/report')
      expect(response).to render_template('results/event_status/_report')
    end

    it "should call the event_status_data_by_areas method to get the overall data for the campaign" do
      expect_any_instance_of(Campaign).to receive(:event_status_data_by_staff).and_return([])
      xhr :post, 'report', report: { campaign_id: campaign.id, group_by: 'staff' }, format: :js
      expect(response).to be_success
      expect(response).to render_template('results/event_status/report')
      expect(response).to render_template('results/event_status/_report')
    end
  end

  describe "POST 'index'" do
    it "should return http success" do
      Sunspot.commit
      post 'index', "report"=>{"campaign_id"=>campaign.id}
      expect(response).to be_success
    end
  end
end