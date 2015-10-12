require 'rails_helper'

describe Api::V1::CampaignsController, type: :controller do
  let(:user) { sign_in_as_user }
  let(:company) { user.company_users.first.company }
  let(:campaign) { create(:campaign, company: company, name: 'Cerveza Imperial FY14') }

  before { set_api_authentication_headers user, company }

  describe "GET 'all'"do
    it 'return a list of events' do
      campaign
      create(:campaign, company: company, name: 'Cerveza Imperial FY14', aasm_state: 'closed')
      create(:campaign, company: company, name: 'Cerveza Imperial FY14', aasm_state: 'inactive')

      get :all, format: :json
      expect(response).to be_success
      result = JSON.parse(response.body)

      expect(result).to match_array([{ 'id' => campaign.id, 'name' => 'Cerveza Imperial FY14' }])
    end
  end

  describe "GET 'overall_stats'"do
    before { Kpi.create_global_kpis }
    it 'return a list of campaings with the info' do
      create(:event, campaign: campaign)
      goal = campaign.goals.for_kpi(Kpi.events)
      goal.value = 200
      goal.save
      goal = campaign.goals.for_kpi(Kpi.promo_hours)
      goal.value = 100
      goal.save

      get :overall_stats, format: :json
      expect(response).to be_success
      results = JSON.parse(response.body)

      expect(results.first).to include('id' => campaign.id, 'name' => 'Cerveza Imperial FY14', 'goal' => 100.0, 'kpi' => 'PROMO HOURS')
      expect(results.second).to include('id' => campaign.id, 'name' => 'Cerveza Imperial FY14', 'goal' => 200.0, 'kpi' => 'EVENTS')
    end
  end

  describe "GET 'stats'"do
    before { Kpi.create_global_kpis }
    it 'return a list of campaings with the info' do
      area = create(:area, name: 'California', company: company)
      area.places << create(:place, city: 'Los Angeles', state: 'California', types: ['political'])
      campaign.areas << area
      create(:goal, parent: campaign, goalable: area, kpi: Kpi.promo_hours, value: 10)

      get :stats, id: campaign.to_param, format: :json
      expect(response).to be_success
      stats = JSON.parse(response.body)

      expect(stats['areas'].first['id']).to eql area.id
      expect(stats['areas'].first['name']).to eql 'California'
      expect(stats['areas'].first['kpi']).to eql 'PROMO HOURS'
      expect(stats['areas'].first['goal']).to eql '10.0'
      expect(stats['areas'].first['executed']).to eql 0.0
      expect(stats['areas'].first['scheduled']).to eql 0.0
      expect(stats['areas'].first['remaining']).to eql '10.0'
      expect(stats['areas'].first['executed_percentage']).to eql 0
      expect(stats['areas'].first['scheduled_percentage']).to eql 0
      expect(stats['areas'].first['remaining_percentage']).to eql 100
      expect(stats['areas'].first.key?('today')).to be_falsey
      expect(stats['areas'].first.key?('today_percentage')).to be_falsey
    end
  end

  describe "GET 'events'"do
    it 'return a list of events the campaign' do
      place = create(:place)
      create_list(:event, 3, company: company, campaign: campaign, place: place)

      get :events, id: campaign.to_param, format: :json
      expect(response).to be_success
      events = JSON.parse(response.body)

      expect(events.count).to eq(3)
    end
  end

  describe "GET 'expense_categories'", :show_in_doc do
    it 'return a list of expense categories for the campaign' do
      categories = %w(Phone Entertainment Fuel Other)
      campaign.update_attribute(:modules, 'expenses' => {
                                  'settings' => { 'categories' => categories } })

      get :expense_categories, id: campaign.to_param, format: :json
      expect(response).to be_success
      expect(json).to eql categories
    end
  end
end
