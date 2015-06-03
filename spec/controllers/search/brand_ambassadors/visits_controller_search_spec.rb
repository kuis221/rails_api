require 'rails_helper'

describe BrandAmbassadors::VisitsController, type: :controller, search: true do
  describe 'As Super User' do
    before(:each) do
      @user = sign_in_as_user
      @company = @user.companies.first
      @company_user = @user.current_company_user
    end

    let(:campaign) { create(:campaign, company: @company) }

    it 'returns the list of visits' do
      visit = create(:brand_ambassadors_visit,
                     visit_type: 'market_visit', start_date: '08/26/2014', end_date: '08/27/2014',
                     company: @company, campaign: campaign, active: true)
      Sunspot.commit
      get 'index', format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result).to eql [
        { 'visit_type_name' => 'Formal Market Visit',
          'campaign_name' => campaign.name,
          'color' => campaign.color, 'city' => visit.city,
          'start' => '2014-08-26', 'end' => '2014-08-27T23:59:59.999-07:00',
          'url' => "http://test.host/brand_ambassadors/visits/#{visit.id}",
          'company_user' => { 'full_name' => @user.full_name } }
      ]
    end
  end

end
