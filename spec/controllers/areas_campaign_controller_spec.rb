require 'rails_helper'

describe AreasCampaignsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
  end

  let(:company) { @user.companies.first }
  let(:area) { create(:area, company: company) }
  let(:campaign) { create(:campaign, company: company) }
  let(:place) { create(:place, name: 'Place 1') }

  describe "GET 'edit'" do
    before { campaign.areas << area }
    it 'response is success' do
      xhr :get, 'edit', campaign_id: campaign.id, id: area.to_param, format: :js
      expect(response).to be_success
      expect(response).to render_template '_form'
    end
  end

  describe "POST 'add_place'" do
    before { campaign.areas << area }
    it 'add the place to the inclusions list' do
      xhr :post, 'add_place', campaign_id: campaign.id, id: area.to_param, areas_campaign: { reference: place.id.to_s }, format: :js
      expect(response).to be_success
      expect(response).to render_template 'add_place'
      expect(campaign.areas_campaigns.first.inclusions).to eql [place.id]
    end

    it 'try add a repeated place to the inclusions list' do
      campaign.areas_campaigns.first.update_column :inclusions, [place.id.to_s]
      xhr :post, 'add_place', campaign_id: campaign.id, id: area.to_param, areas_campaign: { reference: place.id.to_s }, format: :js
      expect(response).to be_success
      expect(response).to render_template 'add_place'
      expect(campaign.areas_campaigns.first.inclusions).to eql [place.id]
    end

    it 'try to add the place to the inclusions list sending an empty place reference' do
      xhr :post, 'add_place', campaign_id: campaign.id, id: area.to_param, areas_campaign: { reference: '' }, format: :js
      expect(response).to be_success
      expect(response).to render_template 'add_place'
      expect(campaign.areas_campaigns.first.inclusions).to eql []
    end
  end

  describe "POST 'exclude_place'" do
    before { campaign.areas << area }
    it 'add the place to the exclusions list' do
      xhr :post, 'exclude_place', campaign_id: campaign.id, id: area.to_param, place_id: 99, format: :js
      expect(response).to be_success
      expect(response).to render_template 'exclude_place'
      expect(campaign.areas_campaigns.first.exclusions).to eql [99]
    end
  end

  describe "POST 'include_place'" do
    before { campaign.areas << area }
    it 'add the place to the exclusions list' do
      campaign.areas_campaigns.first.update_column :exclusions, [99, 100]
      xhr :post, 'include_place', campaign_id: campaign.id, id: area.to_param, place_id: 99, format: :js
      expect(response).to be_success
      expect(response).to render_template 'include_place'
      expect(campaign.areas_campaigns.first.reload.exclusions).to eql [100]
    end
  end

end
