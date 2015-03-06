require 'rails_helper'

describe CampaignsController, type: :controller, search: true do
  let(:user) { sign_in_as_user }
  let(:company) { user.companies.first }
  let(:company_user) { user.current_company_user }

  before { user }

  describe "POST 'find_similar_kpi'" do
    it 'should return empty if there are no kpis' do
      get 'find_similar_kpi', name: 'brands'
      results = JSON.parse(response.body)
      expect(results).to be_empty
    end

    it 'should return the kpi if there is one with the same name' do
      create(:kpi, name: 'Number Events', company: company)
      Sunspot.commit
      get 'find_similar_kpi', name: 'Number Events'
      results = JSON.parse(response.body)
      expect(results).not_to be_empty

      expect(results.length).to eq(1)
    end

    it 'should return the kpi if there is one with a similar name' do
      create(:kpi, name: 'Number Events', company: company)
      Sunspot.commit
      get 'find_similar_kpi', name: 'Number of Events'
      results = JSON.parse(response.body)
      expect(results).not_to be_empty

      expect(results.length).to eq(1)
    end

    it 'should return the kpi if there is one with the same word but in singular' do
      create(:kpi, name: 'Events', company: company)
      Sunspot.commit
      get 'find_similar_kpi', name: 'Event'
      results = JSON.parse(response.body)
      expect(results).not_to be_empty

      expect(results.length).to eq(1)
    end
  end

end
