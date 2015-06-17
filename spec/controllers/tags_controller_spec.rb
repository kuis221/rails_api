require 'rails_helper'

describe TagsController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }
  let(:tag) { create(:tag, name: 'tag1', company_id: company) }
  let(:event) { create(:event, campaign: create(:campaign, company: company)) }
  let(:attached_asset) {  create(:attached_asset, attachable: event) }

  before(:each) { user }

  describe "GET 'remove'" do
    it 'removes an active tag from a photo' do
      attached_asset.tags << tag
      xhr :get, 'remove', id: tag.to_param, attached_asset_id: attached_asset.to_param, format: :js
      expect(response).to be_success
    end
  end

  describe "GET 'activate'" do
    it 'assigns a tag to the photo' do
      xhr :get, 'activate', id: tag.to_param, attached_asset_id: attached_asset.to_param, format: :js
      expect(response).to be_success
      expect(attached_asset.tags.to_a).to eql [tag]
    end

    it 'creates and assigns a new tag the photo' do
      expect do
        xhr :get, 'activate', id: 'cool', attached_asset_id: attached_asset.to_param, format: :js
      end.to change(Tag, :count).by(1)
      expect(response).to be_success
      expect(attached_asset.tags.pluck(:name)).to eql ['cool']
    end
  end
end
