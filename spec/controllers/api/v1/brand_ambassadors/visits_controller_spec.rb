require 'rails_helper'

describe Api::V1::BrandAmbassadors::VisitsController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }

  before { set_api_authentication_headers user, company }

  describe "GET 'index'", search: true do
    it 'return a list of events' do
      campaign = create(:campaign, company: company)
      create_list(:brand_ambassadors_visit, 3, company: company, campaign: campaign)
      Sunspot.commit

      get :index, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(3)
      expect(result['total']).to eq(3)
      expect(result['page']).to eq(1)
      expect(result['results'].first.keys).to match_array(%w(id start_date end_date status))
    end

    it 'sencond page returns empty results' do
      campaign = create(:campaign, company: company)
      create_list(:brand_ambassadors_visit, 3, company: company, campaign: campaign)
      Sunspot.commit

      get :index, page: 2, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(0)
      expect(result['total']).to eq(3)
      expect(result['page']).to eq(2)
      expect(result['results']).to be_empty
    end

    it 'return a list of visits filtered by campaign id' do
      campaign = create(:campaign, company: company)
      other_campaign = create(:campaign, company: company)
      create_list(:brand_ambassadors_visit, 3, company: company, campaign: campaign)
      create_list(:brand_ambassadors_visit, 3, company: company, campaign: other_campaign)
      Sunspot.commit

      get :index, campaign: [campaign.id], format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(3)
    end

    it 'return the facets for the search' do
      campaign = create(:campaign, company: company)
      place = create(:place)
      create(:approved_event, company: company, campaign: campaign, place: place)
      create(:rejected_event, company: company, campaign: campaign, place: place)
      create(:submitted_event, company: company, campaign: campaign, place: place)
      create(:late_event, company: company, campaign: campaign, place: place)

      # Make sure custom filters are not returned
      create(:custom_filter, owner: company, group: 'SAVED FILTERS', apply_to: 'events')

      Sunspot.commit

      get :index, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result['results'].count).to eq(4)
      expect(result['facets'].map { |f| f['label'] }).to match_array(['Campaigns', 'Brands', 'Areas', 'People', 'Active State', 'Event Status'])

      expect(
        result['facets'].find { |f| f['label'] == 'Event Status' }['items'].map do |i|
          [i['label'], i['count']]
        end
      ).to match_array([
        ['Late', 1], ['Due', 1], ['Submitted', 1],
        ['Rejected', 1], ['Approved', 1]])
    end

    it 'should not include the facets when the page is greater than 1' do
      get :index, page: 2, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)
      expect(result['results']).to eq([])
      expect(result['facets']).to be_nil
      expect(result['page']).to eq(2)
    end
  end
end
