require 'rails_helper'

describe CampaignsController, type: :controller, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
    Sunspot.commit
  end

  describe "GET 'autocomplete'" do

    it 'should return the correct buckets in the right order' do
      Sunspot.commit
      get 'autocomplete'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map { |b| b['label'] }).to eq(%w(Campaigns Brands Places People))
    end

    it 'should return the users in the People Bucket' do
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', q: 'gu'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => '<i>Gu</i>illermo Vargas', 'value' => company_user.id.to_s, 'type' => 'company_user' }])
    end

    it 'should return the teams in the People Bucket' do
      team = create(:team, name: 'Spurs', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'sp'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => '<i>Sp</i>urs', 'value' => team.id.to_s, 'type' => 'team' }])
    end

    it 'should return the teams and users in the People Bucket' do
      team = create(:team, name: 'Valladolid', company_id: @company.id)
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', q: 'va'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => '<i>Va</i>lladolid', 'value' => team.id.to_s, 'type' => 'team' }, { 'label' => 'Guillermo <i>Va</i>rgas', 'value' => company_user.id.to_s, 'type' => 'company_user' }])
    end

    it 'should return the campaigns in the Campaigns Bucket' do
      campaign = create(:campaign, name: 'Cacique para todos', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      campaigns_bucket = buckets.select { |b| b['label'] == 'Campaigns' }.first
      expect(campaigns_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique para todos', 'value' => campaign.id.to_s, 'type' => 'campaign' }])
    end

    it 'should return the brands in the Brands Bucket' do
      brand = create(:brand, name: 'Cacique', company_id: @company)
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      brands_bucket = buckets.select { |b| b['label'] == 'Brands' }.first
      expect(brands_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique', 'value' => brand.id.to_s, 'type' => 'brand' }])
    end

    it 'should return the venues in the Places Bucket' do
      expect_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
      venue = create(:venue, company_id: @company.id, place: create(:place, name: 'Motel Paraiso'))
      Sunspot.commit

      get 'autocomplete', q: 'mot'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      places_bucket = buckets.select { |b| b['label'] == 'Places' }.first
      expect(places_bucket['value']).to eq([{ 'label' => '<i>Mot</i>el Paraiso', 'value' => venue.id.to_s, 'type' => 'venue' }])
    end
  end

  describe "GET 'filters'" do
    it 'should return the correct filters in the right order' do
      Sunspot.commit
      get 'filters', format: :json
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map { |b| b['label'] }).to eq(['Brands', 'Brand Portfolios', 'People', 'Active State'])
    end
  end

  describe "POST 'find_similar_kpi'" do
    it 'should return empty if there are no kpis' do
      get 'find_similar_kpi', name: 'brands'
      results = JSON.parse(response.body)
      expect(results).to be_empty
    end

    it 'should return the kpi if there is one with the same name' do
      create(:kpi, name: 'Number Events', company: @company)
      Sunspot.commit
      get 'find_similar_kpi', name: 'Number Events'
      results = JSON.parse(response.body)
      expect(results).not_to be_empty

      expect(results.length).to eq(1)
    end

    it 'should return the kpi if there is one with a similar name' do
      create(:kpi, name: 'Number Events', company: @company)
      Sunspot.commit
      get 'find_similar_kpi', name: 'Number of Events'
      results = JSON.parse(response.body)
      expect(results).not_to be_empty

      expect(results.length).to eq(1)
    end

    it 'should return the kpi if there is one with the same word but in singular' do
      create(:kpi, name: 'Events', company: @company)
      Sunspot.commit
      get 'find_similar_kpi', name: 'Event'
      results = JSON.parse(response.body)
      expect(results).not_to be_empty

      expect(results.length).to eq(1)
    end
  end

end
