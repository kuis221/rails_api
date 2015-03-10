require 'rails_helper'

describe AutocompleteController, type: :controller, search: true do
  let(:user) { sign_in_as_user }
  let(:company_user) { user.current_company_user }
  let(:company) { user.companies.first }
  let(:campaign) { create(:campaign, company: company) }

  before { user }

  describe 'Events' do
    it 'returns the correct buckets in the right order' do
      get 'show', id: 'events', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq([
        'Campaigns', 'Brands', 'Places', 'People', 'Active State', 'Event Status'])
    end

    it 'returns the users in the People Bucket' do
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'events', q: 'gu', format: :json
      expect(response).to be_success

      people_bucket = json.find { |b| b['label'] == 'People' }
      expect(people_bucket['value']).to eq([
        { 'label' => '<i>Gu</i>illermo Vargas', 'value' => company_user.id.to_s,
          'type' => 'user' }])
    end

    it 'should exclude the users in the :user param' do
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      excluded_user = create(:user, first_name: 'Guillermo', last_name: 'Tell', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'events', q: 'gu', user: [excluded_user.company_users.first.id], format: :json
      expect(response).to be_success

      people_bucket = json.find { |b| b['label'] == 'People' }
      expect(people_bucket['value']).to eq([
        { 'label' => '<i>Gu</i>illermo Vargas', 'value' => company_user.id.to_s,
          'type' => 'user' }])
    end

    it 'returns the teams in the People Bucket' do
      team = create(:team, name: 'Spurs', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'events', q: 'sp'
      expect(response).to be_success

      people_bucket = json.find { |b| b['label'] == 'People' }
      expect(people_bucket['value']).to eq([
        { 'label' => '<i>Sp</i>urs', 'value' => team.id.to_s, 'type' => 'team' }])
    end

    it 'should exclude teams in the :team param' do
      team = create(:team, name: 'Spurs', company_id: company.id)
      excluded_team = create(:team, name: 'Spurs Jr', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'events', q: 'sp', team: [excluded_team.id], format: :json
      expect(response).to be_success

      people_bucket = json.find { |b| b['label'] == 'People' }
      expect(people_bucket['value']).to eq([
        { 'label' => '<i>Sp</i>urs', 'value' => team.id.to_s, 'type' => 'team' }])
    end

    it 'returns the teams and users in the People Bucket' do
      team = create(:team, name: 'Valladolid', company_id: company.id)
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'events', q: 'va'
      expect(response).to be_success

      people_bucket = json.find { |b| b['label'] == 'People' }
      expect(people_bucket['value']).to eq([
        { 'label' => '<i>Va</i>lladolid', 'value' => team.id.to_s, 'type' => 'team' },
        { 'label' => 'Guillermo <i>Va</i>rgas', 'value' => company_user.id.to_s,
          'type' => 'user' }
      ])
    end

    it 'returns the campaigns in the Campaigns Bucket' do
      campaign = create(:campaign, name: 'Cacique para todos', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'events', q: 'cac', format: :json
      expect(response).to be_success

      campaigns_bucket = json.find { |b| b['label'] == 'Campaigns' }
      expect(campaigns_bucket['value']).to eq([
        { 'label' => '<i>Cac</i>ique para todos', 'value' => campaign.id.to_s,
          'type' => 'campaign' }
      ])
    end

    it 'should exclude the campaigns that are in the campaign param' do
      campaign = create(:campaign, name: 'Cacique para todos', company: company)
      excluded_campaign = create(:campaign, name: 'Cacique para nadie', company: company)
      Sunspot.commit

      get 'show', id: 'events', q: 'cac', campaign: [excluded_campaign.id], format: :json
      expect(response).to be_success

      campaigns_bucket = json.find { |b| b['label'] == 'Campaigns' }
      expect(campaigns_bucket['value']).to eq([
        { 'label' => '<i>Cac</i>ique para todos', 'value' => campaign.id.to_s,
          'type' => 'campaign' }
      ])
    end

    it 'returns the brands in the Brands Bucket' do
      brand = create(:brand, name: 'Cacique', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'events', q: 'cac'
      expect(response).to be_success

      brands_bucket = json.find { |b| b['label'] == 'Brands' }
      expect(brands_bucket['value']).to eq([
        { 'label' => '<i>Cac</i>ique', 'value' => brand.id.to_s, 'type' => 'brand' }])
    end

    it 'returns the venues in the Places Bucket' do
      expect_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
      venue = create(:venue, company_id: company.id, place: create(:place, name: 'Motel Paraiso'))
      Sunspot.commit

      get 'show', id: 'events', q: 'mot', format: :json
      expect(response).to be_success

      places_bucket = json.find { |b| b['label'] == 'Places' }
      expect(places_bucket['value']).to eq([
        { 'label' => '<i>Mot</i>el Paraiso', 'value' => venue.id.to_s, 'type' => 'venue' }
      ])
    end

    it 'returns inactive in the Active State Bucket' do
      get 'show', id: 'events', q: 'inact', format: :json
      expect(response).to be_success

      places_bucket = json.find { |b| b['label'] == 'Active State' }
      expect(places_bucket['value']).to eq([
        { 'label' => '<i>Inact</i>ive', 'value' => 'Inactive', 'type' => 'status' }
      ])
    end
  end

  describe 'Activity Types' do
    it 'returns the correct buckets in the right order' do
      Sunspot.commit
      get 'show', id: 'activity_types'
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq(['Activity Types', 'Active State'])
    end

    it 'returns the brands in the Day parts Bucket' do
      activity_type = create(:activity_type, name: 'Activity Type 1', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'activity_types', q: 'act', format: :json
      expect(response).to be_success

      activity_type_bucket = json.select { |b| b['label'] == 'Activity Types' }.first
      expect(activity_type_bucket['value']).to eq([
        { 'label' => '<i>Act</i>ivity Type 1', 'value' => activity_type.id.to_s, 'type' => 'activity_type' }
      ])
    end
  end

  describe 'Areas' do
    it "should return the correct buckets in the right order when the user is in the 'teams' scope" do
      get 'show', id: 'areas', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq([
        'Areas', 'Active State'])
    end

    it 'returns the areas in the Area Bucket' do
      t = create(:area, name: 'Test Area', description: 'Test Area description', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'areas', q: 'te', format: :json
      expect(response).to be_success

      area_bucket = json.select { |b| b['label'] == 'Areas' }.first
      expect(area_bucket['value']).to eq([{ 'label' => '<i>Te</i>st Area', 'value' => t.id.to_s, 'type' => 'area' }])
    end
  end

  describe 'Brand Portfolios' do
    it 'returns the correct buckets in the right order' do
      Sunspot.commit
      get 'show', id: 'brand_portfolios', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq([
        'Brand Portfolios', 'Brands', 'Active State'])
    end

    it 'returns the brands in the Brands Bucket' do
      brand = create(:brand, name: 'Cacique', company_id: company)
      Sunspot.commit

      get 'show', id: 'brand_portfolios', q: 'cac', format: :json
      expect(response).to be_success

      brands_bucket = json.select { |b| b['label'] == 'Brands' }.first
      expect(brands_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique', 'value' => brand.id.to_s, 'type' => 'brand' }])
    end
  end

  describe 'Brands' do
    it 'returns the correct buckets in the right order' do
      Sunspot.commit
      get 'show', id: 'brands', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq([
        'Brands', 'Active State'])
    end

    it 'returns the campaigns in the Campaigns Bucket' do
      brand = create(:brand, name: 'Cacique para todos', company: company)
      Sunspot.commit

      get 'show', id: 'brands', q: 'cac', format: :json
      expect(response).to be_success

      campaigns_bucket = json.select { |b| b['label'] == 'Brands' }.first
      expect(campaigns_bucket['value']).to eq([
        {
          'label' => '<i>Cac</i>ique para todos',
          'value' => brand.id.to_s, 'type' => 'brand'
        }])
    end
  end

  describe 'Campaigns' do
    it 'returns the correct buckets in the right order' do
      get 'show', id: 'campaigns', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq([
        'Campaigns', 'Brands', 'Places', 'People', 'Active State'])
    end

    it 'returns the users in the People Bucket' do
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'campaigns', format: :json, q: 'gu'
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => '<i>Gu</i>illermo Vargas', 'value' => company_user.id.to_s, 'type' => 'user' }])
    end

    it 'returns the teams in the People Bucket' do
      team = create(:team, name: 'Spurs', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'campaigns', format: :json, q: 'sp'
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => '<i>Sp</i>urs', 'value' => team.id.to_s, 'type' => 'team' }])
    end

    it 'returns the teams and users in the People Bucket' do
      team = create(:team, name: 'Valladolid', company_id: company.id)
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'campaigns', format: :json, q: 'va'
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([
        {
          'label' => '<i>Va</i>lladolid',
          'value' => team.id.to_s,
          'type' => 'team' },
        { 'label' => 'Guillermo <i>Va</i>rgas',
          'value' => company_user.id.to_s,
          'type' => 'user' }])
    end

    it 'returns the campaigns in the Campaigns Bucket' do
      campaign = create(:campaign, name: 'Cacique para todos', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'campaigns', format: :json, q: 'cac'
      expect(response).to be_success

      campaigns_bucket = json.select { |b| b['label'] == 'Campaigns' }.first
      expect(campaigns_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique para todos', 'value' => campaign.id.to_s, 'type' => 'campaign' }])
    end

    it 'returns the brands in the Brands Bucket' do
      brand = create(:brand, name: 'Cacique', company_id: company)
      Sunspot.commit

      get 'show', id: 'campaigns', format: :json, q: 'cac'
      expect(response).to be_success

      brands_bucket = json.select { |b| b['label'] == 'Brands' }.first
      expect(brands_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique', 'value' => brand.id.to_s, 'type' => 'brand' }])
    end

    it 'returns the venues in the Places Bucket' do
      expect_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
      venue = create(:venue, company_id: company.id, place: create(:place, name: 'Motel Paraiso'))
      Sunspot.commit

      get 'show', id: 'campaigns', format: :json, q: 'mot'
      expect(response).to be_success

      places_bucket = json.select { |b| b['label'] == 'Places' }.first
      expect(places_bucket['value']).to eq([{ 'label' => '<i>Mot</i>el Paraiso', 'value' => venue.id.to_s, 'type' => 'venue' }])
    end
  end

  describe 'Company Users' do
    it 'returns the correct buckets in the right order' do
      get 'show', id: 'company_users', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq([
        'Users', 'Teams', 'Roles', 'Campaigns', 'Places', 'Active State'])
    end

    it 'returns the users in the User Bucket' do
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'company_users', format: :json, q: 'gu'
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'Users' }.first
      expect(people_bucket['value']).to eq([
        { 'label' => '<i>Gu</i>illermo Vargas',
          'value' => company_user.id.to_s, 'type' => 'user' }])
    end

    it 'returns the teams in the Teams Bucket' do
      team = create(:team, name: 'Spurs', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'company_users', format: :json, q: 'sp'
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'Teams' }.first
      expect(people_bucket['value']).to eq([
        { 'label' => '<i>Sp</i>urs', 'value' => team.id.to_s, 'type' => 'team' }])
    end

    it 'returns the campaigns in the Campaigns Bucket' do
      campaign = create(:campaign, name: 'Cacique para todos', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'company_users', format: :json, q: 'cac'
      expect(response).to be_success

      campaigns_bucket = json.select { |b| b['label'] == 'Campaigns' }.first
      expect(campaigns_bucket['value']).to eq([
        { 'label' => '<i>Cac</i>ique para todos',
          'value' => campaign.id.to_s, 'type' => 'campaign' }])
    end

    it 'returns the roles in the Roles Bucket' do
      role = create(:role, name: 'Campaing Staff', company: company)
      Sunspot.commit

      get 'show', id: 'company_users', format: :json, q: 'staff'
      expect(response).to be_success

      places_bucket = json.select { |b| b['label'] == 'Roles' }.first
      expect(places_bucket['value']).to eq([
        { 'label' => 'Campaing <i>Staff</i>', 'value' => role.id.to_s, 'type' => 'role' }])
    end

    it 'returns the venues in the Places Bucket' do
      expect_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
      venue = create(:venue, company_id: company.id, place: create(:place, name: 'Motel Paraiso'))
      Sunspot.commit

      get 'show', id: 'company_users', format: :json, q: 'mot'
      expect(response).to be_success

      places_bucket = json.select { |b| b['label'] == 'Places' }.first
      expect(places_bucket['value']).to eq([
        { 'label' => '<i>Mot</i>el Paraiso', 'value' => venue.id.to_s, 'type' => 'venue' }])
    end
  end

  describe 'Day Parts' do
    it 'returns the correct buckets in the right order' do
      get 'show', id: 'day_parts', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq(['Day Parts', 'Active State'])
    end

    it 'returns the day part in the Day parts Bucket' do
      day_part = create(:day_part, name: 'Part 1', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'day_parts', format: :json, q: 'par'
      expect(response).to be_success

      day_parts_bucket = json.select { |b| b['label'] == 'Day Parts' }.first
      expect(day_parts_bucket['value']).to eq([
        { 'label' => '<i>Par</i>t 1', 'value' => day_part.id.to_s, 'type' => 'day_part' }])
    end
  end

  describe 'Roles' do
    it 'returns the correct buckets in the right order' do
      get 'show', id: 'roles', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq(['Roles', 'Active State'])
    end

    it 'returns the roles in the Roles Bucket' do
      role = create(:role, name: 'Role 1', company: company)
      Sunspot.commit

      get 'show', id: 'roles', format: :json, q: 'rol'
      expect(response).to be_success

      roles_bucket = json.select { |b| b['label'] == 'Roles' }.first
      expect(roles_bucket['value']).to eq([{ 'label' => '<i>Rol</i>e 1', 'value' => role.id.to_s, 'type' => 'role' }])
    end
  end

  describe 'Tasks' do
    it 'returns the correct buckets in the right order' do
      get 'show', id: 'user_tasks', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq(['Tasks', 'Campaigns', 'Task Status', 'Active State'])
    end

    it "should return the correct buckets in the right order for team tasks" do
      get 'show', id: 'teams_tasks', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq([
        'Tasks', 'Campaigns', 'People', 'Task Status', 'Active State'])
    end

    it 'returns the users in the People Bucket' do
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'teams_tasks', format: :json, q: 'gu'
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => '<i>Gu</i>illermo Vargas', 'value' => company_user.id.to_s, 'type' => 'user' }])
    end

    it 'returns the teams in the People Bucket' do
      team = create(:team, name: 'Spurs', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'teams_tasks', format: :json, q: 'sp'
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => '<i>Sp</i>urs', 'value' => team.id.to_s, 'type' => 'team' }])
    end

    it 'returns the teams and users in the People Bucket' do
      team = create(:team, name: 'Valladolid', company_id: company.id)
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'teams_tasks', format: :json, q: 'va'
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => '<i>Va</i>lladolid', 'value' => team.id.to_s, 'type' => 'team' }, { 'label' => 'Guillermo <i>Va</i>rgas', 'value' => company_user.id.to_s, 'type' => 'user' }])
    end

    it 'returns the campaigns in the Campaigns Bucket' do
      campaign = create(:campaign, name: 'Cacique para todos', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'teams_tasks', format: :json, q: 'cac'
      expect(response).to be_success

      campaigns_bucket = json.select { |b| b['label'] == 'Campaigns' }.first
      expect(campaigns_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique para todos', 'value' => campaign.id.to_s, 'type' => 'campaign' }])
    end

    it 'returns the tasks in the Tasks Bucket' do
      task = create(:task, title: 'Bring the beers', event: create(:event, company_id: company.id))
      Sunspot.commit

      get 'show', id: 'teams_tasks', format: :json, q: 'Bri'
      expect(response).to be_success

      tasks_bucket = json.select { |b| b['label'] == 'Tasks' }.first
      expect(tasks_bucket['value']).to eq([{ 'label' => '<i>Bri</i>ng the beers', 'value' => task.id.to_s, 'type' => 'task' }])
    end
  end

  describe 'Teams' do
    it 'returns the correct buckets in the right order' do
      get 'show', id: 'teams', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq([
        'Teams', 'Users', 'Campaigns', 'Active State'])
    end

    it 'returns the teams in the Teams Bucket' do
      team = create(:team, name: 'Team 1', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'teams', format: :json, q: 'tea'
      expect(response).to be_success

      teams_bucket = json.select { |b| b['label'] == 'Teams' }.first
      expect(teams_bucket['value']).to eq([{ 'label' => '<i>Tea</i>m 1', 'value' => team.id.to_s, 'type' => 'team' }])
    end

    it 'returns the users in the Users Bucket' do
      user = create(:user, first_name: 'Juanito', last_name: 'Bazooka', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'teams', format: :json, q: 'ju'
      expect(response).to be_success

      users_bucket = json.select { |b| b['label'] == 'Users' }.first
      expect(users_bucket['value']).to eq([{ 'label' => '<i>Ju</i>anito Bazooka', 'value' => company_user.id.to_s, 'type' => 'user' }])
    end

    it 'returns the campaigns in the Campaigns Bucket' do
      campaign = create(:campaign, name: 'Campaign 1', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'teams', format: :json, q: 'cam'
      expect(response).to be_success

      campaigns_bucket = json.select { |b| b['label'] == 'Campaigns' }.first
      expect(campaigns_bucket['value']).to eq([{ 'label' => '<i>Cam</i>paign 1', 'value' => campaign.id.to_s, 'type' => 'campaign' }])
    end
  end

  describe 'Results Photos' do
    it 'returns the correct buckets in the right order' do
      get 'show', id: 'results_photos', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq(['Campaigns', 'Brands', 'Places', 'Active State'])
    end

    it 'returns the campaigns in the Campaigns Bucket' do
      campaign = create(:campaign, name: 'Cacique para todos', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'results_photos', format: :json, q: 'cac'
      expect(response).to be_success

      campaigns_bucket = json.select { |b| b['label'] == 'Campaigns' }.first
      expect(campaigns_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique para todos', 'value' => campaign.id.to_s, 'type' => 'campaign' }])
    end

    it 'returns the brands in the Brands Bucket' do
      brand = create(:brand, name: 'Cacique', company_id: company)
      Sunspot.commit

      get 'show', id: 'results_photos', format: :json, q: 'cac'
      expect(response).to be_success

      brands_bucket = json.select { |b| b['label'] == 'Brands' }.first
      expect(brands_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique', 'value' => brand.id.to_s, 'type' => 'brand' }])
    end

    it 'returns the venues in the Places Bucket' do
      expect_any_instance_of(Place).to receive(:fetch_place_data).and_return(true)
      venue = create(:venue, company_id: company.id, place: create(:place, name: 'Motel Paraiso'))
      Sunspot.commit

      get 'show', id: 'results_photos', format: :json, q: 'mot'
      expect(response).to be_success

      places_bucket = json.select { |b| b['label'] == 'Places' }.first
      expect(places_bucket['value']).to eq([{ 'label' => '<i>Mot</i>el Paraiso', 'value' => venue.id.to_s, 'type' => 'venue' }])
    end
  end

  describe 'Venues', search: true do
    it 'should return the correct buckets in the right order' do
      get 'show', id: 'venues', q: '', format: :json
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq(%w(Places Campaigns Brands People))
    end

    it 'should return the users in the People Bucket' do
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'venues', q: 'gu', format: :json
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{
        'label' => '<i>Gu</i>illermo Vargas',
        'value' => company_user.id.to_s,
        'type' => 'user' }])
    end

    it 'should return the teams in the People Bucket' do
      team = create(:team, name: 'Spurs', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'venues', q: 'sp', format: :json
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => '<i>Sp</i>urs', 'value' => team.id.to_s, 'type' => 'team' }])
    end

    it 'should return the teams and users in the People Bucket' do
      team = create(:team, name: 'Valladolid', company_id: company.id)
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'venues', q: 'va', format: :json
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([
        { 'label' => '<i>Va</i>lladolid',
          'value' => team.id.to_s,
          'type' => 'team' },
        { 'label' => 'Guillermo <i>Va</i>rgas',
          'value' => company_user.id.to_s,
          'type' => 'user' }])
    end

    it 'should return the campaigns in the Campaigns Bucket' do
      campaign = create(:campaign, name: 'Cacique para todos', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'venues', q: 'cac', format: :json
      expect(response).to be_success

      campaigns_bucket = json.select { |b| b['label'] == 'Campaigns' }.first
      expect(campaigns_bucket['value']).to eq([{
        'label' => '<i>Cac</i>ique para todos',
        'value' => campaign.id.to_s,
        'type' => 'campaign' }])
    end

    it 'should return the brands in the Brands Bucket' do
      brand = create(:brand, name: 'Cacique', company_id: company.to_param)
      Sunspot.commit

      get 'show', id: 'venues', q: 'cac', format: :json
      expect(response).to be_success

      brands_bucket = json.select { |b| b['label'] == 'Brands' }.first
      expect(brands_bucket['value']).to eq([{ 'label' => '<i>Cac</i>ique', 'value' => brand.id.to_s, 'type' => 'brand' }])
    end

    it 'should return the areas in the Places Bucket' do
      area = create(:area, company_id: company.id, name: 'Guanacaste')
      Sunspot.commit

      get 'show', id: 'venues', q: 'gua', format: :json
      expect(response).to be_success

      places_bucket = json.select { |b| b['label'] == 'Places' }.first
      expect(places_bucket['value']).to eq([{ 'label' => '<i>Gua</i>nacaste', 'value' => area.id.to_s, 'type' => 'area' }])
    end

    it 'should return the venues in the Places Bucket' do
      venue = create(:venue, company_id: company.id,
                     place: create(:place, name: 'Guanacaste'))
      Sunspot.commit

      get 'show', id: 'venues', q: 'gua', format: :json
      expect(response).to be_success

      places_bucket = json.select { |b| b['label'] == 'Places' }.first
      expect(places_bucket['value']).to eq([{ 'label' => '<i>Gua</i>nacaste', 'value' => venue.id.to_s, 'type' => 'venue' }])
    end
  end

  describe 'Brand Ambassadors Visits' do
    it 'should return the correct buckets in the right order' do
      get 'show', id: 'visits'
      expect(response).to be_success

      expect(json.map { |b| b['label'] }).to eq(%w(Campaigns Places People))
    end

    it 'should return the users in the People Bucket' do
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'visits', q: 'gu'
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => '<i>Gu</i>illermo Vargas', 'value' => company_user.id.to_s, 'type' => 'user' }])
    end

    it 'should return users only in the People Bucket' do
      create(:team, name: 'Valladolid', company_id: company.id)
      user = create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'show', id: 'visits', q: 'va'
      expect(response).to be_success

      people_bucket = json.select { |b| b['label'] == 'People' }.first
      expect(people_bucket['value']).to eq([{ 'label' => 'Guillermo <i>Va</i>rgas', 'value' => company_user.id.to_s, 'type' => 'user' }])
    end

    it 'should return the campaigns in the Campaigns Bucket' do
      campaign = create(:campaign, name: 'Cosmos', company_id: company.id)
      Sunspot.commit

      get 'show', id: 'visits', q: 'cos'
      expect(response).to be_success

      campaigns_bucket = json.select { |b| b['label'] == 'Campaigns' }.first
      expect(campaigns_bucket['value']).to eq([{ 'label' => '<i>Cos</i>mos', 'value' => campaign.id.to_s, 'type' => 'campaign' }])
    end
  end
end
