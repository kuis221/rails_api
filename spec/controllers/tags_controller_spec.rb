require 'rails_helper'

describe TagsController, type: :controller do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @tag = create(:tag, name: 'tag1', company_id: @company)
    @event = create(:event, company: @company, campaign: create(:campaign, company: @company))
    @attached_asset =  create(:attached_asset, attachable: @event)
  end

  describe "GET 'remove'" do

    it 'removes an active tag from a photo' do
      @attached_asset.tags << @tag
      xhr :get, 'remove', id: @tag.to_param, attached_asset_id: @attached_asset.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'activate'" do

    it 'activates an inactive campaign' do
      xhr :get, 'activate', id: @tag.to_param, attached_asset_id: @attached_asset.to_param, format: :js
      expect(response).to be_success
      # campaign.reload.active?.should be_truthy
    end
  end
end
