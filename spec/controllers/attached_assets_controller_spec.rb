require 'rails_helper'

describe AttachedAssetsController, type: :controller, search: true  do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "PUT 'rate'" do
    let(:event){ FactoryGirl.create(:event, company: @company, campaign: FactoryGirl.create(:campaign, company: @company)) }
    let(:attached_asset){ FactoryGirl.create(:attached_asset, attachable: event) }
    it "must update the rating attribute" do
      put 'rate', id: attached_asset.to_param, rating: 2
      expect(response).to be_success
      expect(attached_asset.reload.rating).to eql 2
    end
  end

end