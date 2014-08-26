require 'rails_helper'

describe AreasCampaignsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
  end

  let(:company){ @user.companies.first }
  let(:area){ FactoryGirl.create(:area, company: company) }
  let(:campaign){ FactoryGirl.create(:campaign, company: company) }


  describe "GET 'edit'" do
    before{ campaign.areas << area }
    it "response is success" do
      xhr :get, 'edit', campaign_id: campaign.id, id: area.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template '_form'
    end
  end

  describe "POST 'exclude_place'" do
    before{ campaign.areas << area }
    it "add the place to the exclusions list" do
      xhr :post, 'exclude_place', campaign_id: campaign.id, id: area.to_param, place_id: 99, format: :js
      expect(response).to be_success
      expect(response).to render_template 'exclude_place'
      expect(campaign.areas_campaigns.first.exclusions).to eql [99]
    end
  end

  describe "POST 'include_place'" do
    before{ campaign.areas << area }
    it "add the place to the exclusions list" do
      campaign.areas_campaigns.first.update_column :exclusions, [99,100]
      xhr :post, 'include_place', campaign_id: campaign.id, id: area.to_param, place_id: 99, format: :js
      expect(response).to be_success
      expect(response).to render_template 'include_place'
      expect(campaign.areas_campaigns.first.reload.exclusions).to eql [100]
    end
  end

end