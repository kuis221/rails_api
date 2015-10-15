require 'rails_helper'

RSpec.describe Api::V1::ActivityTypesController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { create(:campaign,  company: company) }

  before { set_api_authentication_headers user, company }

  describe '#index' do
    it 'returns a list of activity types associated to the campaign' do
      create(:activity_type, company: company)
      campaign.activity_types << create(:activity_type, company: company, name: 'MyAT')
      get 'index', campaign_id: campaign.id, format: :json
      expect(response).to be_success
      expect(json.count).to eql 1
      expect(json).to include(
        'id' =>  campaign.activity_types.first.id, 'name' => 'MyAT')
    end

    it 'returns a list of activity types belonging to the current company' do
      company2 = create(:company)
      at1 = create(:activity_type, company: company, name: 'MyAT')
      at2 = create(:activity_type, company: company2, name: 'NotInCompany')
      get 'index', format: :json
      expect(response).to be_success
      expect(json.count).to eql 1
      expect(json).to include(
        'id' =>  at1.id, 'name' => 'MyAT')
      expect(json).not_to include(
        'id' =>  at2.id, 'name' => 'NotInCompany')
    end
  end

  describe '#Campaigns' do
    it 'returns a list of campaigns associated to the activity type' do
      campaign2 = create(:campaign, company: company, name: 'Cerveza Pilsen FY15')
      activity_type = create(:activity_type, company: company)
      activity_type.campaigns << create(:campaign, company: company, name: 'Cerveza Imperial FY14')
      get 'campaigns', id: activity_type.id, format: :json
      expect(response).to be_success

      expect(json.count).to eql 1
      expect(json).to include(
        'id' =>  activity_type.campaigns.first.id, 'name' => 'Cerveza Imperial FY14')
    end

    it 'returns a list of campaigns belonging to the activity type' do
      at1 = create(:activity_type, company: company)
      at2 = create(:activity_type, company: company)
      at1.campaigns << create(:campaign, company: company, name: 'Cerveza Imperial FY14')
      at2.campaigns << create(:campaign, company: company, name: 'Cerveza Pilsen FY14')
      get 'campaigns', id: at1.id, format: :json
      expect(response).to be_success
      expect(json.count).to eql 1
      expect(json).to include(
        'id' =>  at1.campaigns.first.id, 'name' => 'Cerveza Imperial FY14')
      expect(json).not_to include(
        'id' =>  at2.campaigns.first.id, 'name' => 'Cerveza Pilsen FY14')
    end
  end
end
