require 'spec_helper'

describe TasksController, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
    Sunspot.commit
  end

  describe "GET 'items'" do
    describe "counters", search: true do
      describe "within an event" do

        let(:event) { FactoryGirl.create(:event, company_id: @company.id) }

        it "should return the correct number of completed tasks" do
          FactoryGirl.create_list(:completed_task, 3, event: event)

          #Create some other tasks
          FactoryGirl.create(:uncompleted_task, event: event)
          FactoryGirl.create_list(:completed_task, 2, event_id: event.id+1)
          Sunspot.commit

          get 'items', event_id: event.to_param
          assigns(:status_counters)['completed'].should == 3
        end

        it "should return the correct number of assigned tasks" do
          FactoryGirl.create_list(:assigned_task, 3, event: event)

          #Create some other tasks
          FactoryGirl.create(:unassigned_task, event: event)
          FactoryGirl.create_list(:assigned_task, 2, event_id: event.id+1)
          Sunspot.commit

          get 'items', event_id: event.to_param
          assigns(:status_counters)['assigned'].should == 3
        end

        it "should return the correct number of unassigned tasks" do
          FactoryGirl.create_list(:unassigned_task, 3, event: event)

          #Create some other tasks
          FactoryGirl.create(:assigned_task, event: event)
          FactoryGirl.create_list(:unassigned_task, 2, event_id: event.id+1)
          Sunspot.commit

          get 'items', event_id: event.to_param
          assigns(:status_counters)['unassigned'].should == 3
        end

        it "should return the correct number of late tasks" do
          FactoryGirl.create_list(:late_task, 3, event: event)

          #Create some other tasks
          FactoryGirl.create(:future_task, event: event)
          FactoryGirl.create_list(:late_task, 2, event_id: event.id+1)
          Sunspot.commit

          get 'items', event_id: event.to_param
          assigns(:status_counters)['late'].should == 3
        end
      end
    end
  end

  describe "GET 'autocomplete'" do
    it "should return the correct buckets in the right order" do
      get 'autocomplete', scope: :user
      response.should be_success

      buckets = JSON.parse(response.body)
      buckets.map{|b| b['label']}.should == ['Tasks', 'Campaigns']
    end

    it "should return the correct buckets in the right order when the user is in the 'teams' scope" do
      get 'autocomplete', scope: :teams
      response.should be_success

      buckets = JSON.parse(response.body)
      buckets.map{|b| b['label']}.should == ['Tasks', 'Campaigns', 'People']
    end

    it "should return the users in the People Bucket" do
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', scope: :teams, q: 'gu'
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Gu</i>illermo Vargas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
    end

    it "should return the teams in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Spurs', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', scope: :teams, q: 'sp'
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Sp</i>urs", "value"=>team.id.to_s, "type"=>"team"}]
    end

    it "should return the teams and users in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Valladolid', company_id: @company.id)
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', scope: :teams, q: 'va'
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Va</i>lladolid", "value"=>team.id.to_s, "type"=>"team"}, {"label"=>"Guillermo <i>Va</i>rgas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
    end

    it "should return the campaigns in the Campaigns Bucket" do
      campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', scope: :teams, q: 'cac'
      response.should be_success

      buckets = JSON.parse(response.body)
      campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
      campaigns_bucket['value'].should == [{"label"=>"<i>Cac</i>ique para todos", "value"=>campaign.id.to_s, "type"=>"campaign"}]
    end


    it "should return the tasks in the Tasks Bucket" do
      task = FactoryGirl.create(:task, title: 'Bring the beers', event: FactoryGirl.create(:event, company_id: @company.id))
      Sunspot.commit

      get 'autocomplete', scope: :teams, q: 'Bri'
      response.should be_success

      buckets = JSON.parse(response.body)
      tasks_bucket = buckets.select{|b| b['label'] == 'Tasks'}.first
      tasks_bucket['value'].should == [{"label"=>"<i>Bri</i>ng the beers", "value"=>task.id.to_s, "type"=>"task"}]
    end
  end
end
