require 'rails_helper'

RSpec.describe Api::V1::ActivityTypesController, :type => :controller do
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
      result = JSON.parse(response.body)
      expect(result.count).to eql 1
      expect(result).to include(
        'id' =>  campaign.activity_types.first.id, 'name' => 'MyAT')
    end
  end
end
