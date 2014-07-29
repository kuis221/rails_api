require 'spec_helper'

describe TasksController, type: :controller, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
    Sunspot.commit
  end

  describe "GET 'autocomplete'" do
    it "should return the correct buckets in the right order" do
      get 'autocomplete', scope: :user
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map{|b| b['label']}).to eq(['Tasks', 'Campaigns'])
    end

    it "should return the correct buckets in the right order when the user is in the 'teams' scope" do
      get 'autocomplete', scope: :teams
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      expect(buckets.map{|b| b['label']}).to eq(['Tasks', 'Campaigns', 'People'])
    end

    it "should return the users in the People Bucket" do
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', scope: :teams, q: 'gu'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      expect(people_bucket['value']).to eq([{"label"=>"<i>Gu</i>illermo Vargas", "value"=>company_user.id.to_s, "type"=>"company_user"}])
    end

    it "should return the teams in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Spurs', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', scope: :teams, q: 'sp'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      expect(people_bucket['value']).to eq([{"label"=>"<i>Sp</i>urs", "value"=>team.id.to_s, "type"=>"team"}])
    end

    it "should return the teams and users in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Valladolid', company_id: @company.id)
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', scope: :teams, q: 'va'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      expect(people_bucket['value']).to eq([{"label"=>"<i>Va</i>lladolid", "value"=>team.id.to_s, "type"=>"team"}, {"label"=>"Guillermo <i>Va</i>rgas", "value"=>company_user.id.to_s, "type"=>"company_user"}])
    end

    it "should return the campaigns in the Campaigns Bucket" do
      campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', scope: :teams, q: 'cac'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
      expect(campaigns_bucket['value']).to eq([{"label"=>"<i>Cac</i>ique para todos", "value"=>campaign.id.to_s, "type"=>"campaign"}])
    end


    it "should return the tasks in the Tasks Bucket" do
      task = FactoryGirl.create(:task, title: 'Bring the beers', event: FactoryGirl.create(:event, company_id: @company.id))
      Sunspot.commit

      get 'autocomplete', scope: :teams, q: 'Bri'
      expect(response).to be_success

      buckets = JSON.parse(response.body)
      tasks_bucket = buckets.select{|b| b['label'] == 'Tasks'}.first
      expect(tasks_bucket['value']).to eq([{"label"=>"<i>Bri</i>ng the beers", "value"=>task.id.to_s, "type"=>"task"}])
    end
  end

  describe "GET 'filters'" do
    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'filters', format: :json, scope: :user
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map{|b| b['label']}).to eq(["Campaigns", "Task Status", "Active State"])
    end

    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'filters', format: :json, scope: :teams
      expect(response).to be_success

      filters = JSON.parse(response.body)
      expect(filters['filters'].map{|b| b['label']}).to eq(["Campaigns","Task Status", "Staff", "Active State"])
    end
  end
end
