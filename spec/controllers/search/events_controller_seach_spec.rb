require 'spec_helper'

describe EventsController, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.companies.first
    @company_user = @user.current_company_user
  end

  describe "GET 'autocomplete'" do
    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'autocomplete'
      response.should be_success

      buckets = JSON.parse(response.body)
      buckets.map{|b| b['label']}.should == ['Campaigns', 'Brands', 'Places', 'People']
    end

    it "should return the users in the People Bucket" do
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', q: 'gu'
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Gu</i>illermo Vargas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
    end

    it "should return the teams in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Spurs', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'sp'
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Sp</i>urs", "value" => team.id.to_s, "type"=>"team"}]
    end

    it "should return the teams and users in the People Bucket" do
      team = FactoryGirl.create(:team, name: 'Valladolid', company_id: @company.id)
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', q: 'va'
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'People'}.first
      people_bucket['value'].should == [{"label"=>"<i>Va</i>lladolid", "value"=>team.id.to_s, "type"=>"team"}, {"label"=>"Guillermo <i>Va</i>rgas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
    end

    it "should return the campaigns in the Campaigns Bucket" do
      campaign = FactoryGirl.create(:campaign, name: 'Cacique para todos', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      response.should be_success

      buckets = JSON.parse(response.body)
      campaigns_bucket = buckets.select{|b| b['label'] == 'Campaigns'}.first
      campaigns_bucket['value'].should == [{"label"=>"<i>Cac</i>ique para todos", "value"=>campaign.id.to_s, "type"=>"campaign"}]
    end

    it "should return the brands in the Brands Bucket" do
      brand = FactoryGirl.create(:brand, name: 'Cacique')
      Sunspot.commit

      get 'autocomplete', q: 'cac'
      response.should be_success

      buckets = JSON.parse(response.body)
      brands_bucket = buckets.select{|b| b['label'] == 'Brands'}.first
      brands_bucket['value'].should == [{"label"=>"<i>Cac</i>ique", "value"=>brand.id.to_s, "type"=>"brand"}]
    end

    it "should return the places in the Places Bucket" do
      Place.any_instance.should_receive(:fetch_place_data).and_return(true)
      place = FactoryGirl.create(:place, name: 'Motel Paraiso')
      Sunspot.commit

      get 'autocomplete', q: 'mot'
      response.should be_success

      buckets = JSON.parse(response.body)
      places_bucket = buckets.select{|b| b['label'] == 'Places'}.first
      places_bucket['value'].should == [{"label"=>"<i>Mot</i>el Paraiso", "value"=>place.id.to_s, "type"=>"place"}]
    end
  end

  describe "GET 'tasks'" do
    describe "counters", search: true do
      describe "within user scope" do

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


end