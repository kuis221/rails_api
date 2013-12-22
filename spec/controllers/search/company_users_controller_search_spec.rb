require 'spec_helper'

describe CompanyUsersController, search: true do
  before(:each) do
    @user = sign_in_as_user
    @company = @user.current_company
    @company_user = @user.current_company_user
  end

  describe "GET 'autocomplete'" do
    it "should return the correct buckets in the right order" do
      Sunspot.commit
      get 'autocomplete'
      response.should be_success

      buckets = JSON.parse(response.body)
      buckets.map{|b| b['label']}.should == ['Users','Teams', 'Roles', 'Campaigns', 'Places']
    end

    it "should return the users in the User Bucket" do
      user = FactoryGirl.create(:user, first_name: 'Guillermo', last_name: 'Vargas', company_id: @company.id)
      company_user = user.company_users.first
      Sunspot.commit

      get 'autocomplete', q: 'gu'
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'Users'}.first
      people_bucket['value'].should == [{"label"=>"<i>Gu</i>illermo Vargas", "value"=>company_user.id.to_s, "type"=>"company_user"}]
    end


    it "should return the teams in the Teams Bucket" do
      team = FactoryGirl.create(:team, name: 'Spurs', company_id: @company.id)
      Sunspot.commit

      get 'autocomplete', q: 'sp'
      response.should be_success

      buckets = JSON.parse(response.body)
      people_bucket = buckets.select{|b| b['label'] == 'Teams'}.first
      people_bucket['value'].should == [{"label"=>"<i>Sp</i>urs", "value" => team.id.to_s, "type"=>"team"}]
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

    it "should return the roles in the Roles Bucket" do
      role = FactoryGirl.create(:role, name: 'Campaing Staff', company: @company)
      Sunspot.commit

      get 'autocomplete', q: 'staff'
      response.should be_success

      buckets = JSON.parse(response.body)
      places_bucket = buckets.select{|b| b['label'] == 'Roles'}.first
      places_bucket['value'].should == [{"label"=>"Campaing <i>Staff</i>", "value"=>role.id.to_s, "type"=>"role"}]
    end

    it "should return the venues in the Places Bucket" do
      Place.any_instance.should_receive(:fetch_place_data).and_return(true)
      venue = FactoryGirl.create(:venue, company_id: @company.id, place: FactoryGirl.create(:place, name: 'Motel Paraiso'))
      Sunspot.commit

      get 'autocomplete', q: 'mot'
      response.should be_success

      buckets = JSON.parse(response.body)
      places_bucket = buckets.select{|b| b['label'] == 'Places'}.first
      places_bucket['value'].should == [{"label"=>"<i>Mot</i>el Paraiso", "value"=>venue.id.to_s, "type"=>"venue"}]
    end
  end

  describe "GET 'notifications'" do
    it "should return a notification if a user is added to a event's team" do
      event = FactoryGirl.create(:event, company: @company)
      event.users << @company_user
      Sunspot.commit

      get 'notifications', id: @company_user.to_param, format: :json

      response.should be_success

      notifications = JSON.parse(response.body)
      notifications.should include({"message" => "You have a new event", "level" => "grey", "url" => event_path(event, notifid: Notification.last.id), "unread" => true, "icon" => "icon-notification-event"})
    end

    it "should return a notification if the user have a late event recap" do
      event = FactoryGirl.create(:late_event, company: @company)
      event.users << @company_user
      Sunspot.commit

      get 'notifications', id: @company_user.to_param, format: :json

      response.should be_success

      notifications = JSON.parse(response.body)
      notifications.should include({"message" => "There is one late event recap", "level"=>"red", "url"=>"/events?end_date=&event_status%5B%5D=Late&start_date=&status%5B%5D=Active&user%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-event"})
    end

    it "should NOT return a notification if the user is not part of the event's team" do
      event = FactoryGirl.create(:late_event, company: @company)
      Sunspot.commit

      get 'notifications', id: @company_user.to_param, format: :json

      response.should be_success

      notifications = JSON.parse(response.body)
      notifications.should == []
    end

    it "should return a notification if the user have a submitted event recap that is waiting for approval" do
      event = FactoryGirl.create(:submitted_event, company: @company)
      event.users << @company_user
      Sunspot.commit

      get 'notifications', id: @company_user.to_param, format: :json

      response.should be_success

      notifications = JSON.parse(response.body)
      notifications.should include({"message"=>"There is one event recap that is pending approval", "level"=>"blue", "url"=>"/events?end_date=&event_status%5B%5D=Submitted&start_date=&status%5B%5D=Active&user%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-event"})
    end

    it "should return a notification if the user have a due event recap" do
      event = FactoryGirl.create(:due_event, company: @company)
      event.users << @company_user
      Sunspot.commit

      get 'notifications', id: @company_user.to_param, format: :json

      response.should be_success

      notifications = JSON.parse(response.body)
      notifications.should include({"message"=>"There is one event recap that is due", "level"=>"grey", "url"=>"/events?end_date=&event_status%5B%5D=Due&start_date=&status%5B%5D=Active&user%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-event"})
    end

    it "should return a notification if the user has is assigned to a task that is late" do
      event = FactoryGirl.create(:event, company: @company)
      task = FactoryGirl.create(:late_task, event: event, company_user_id: @company_user.id)

      Sunspot.commit

      get 'notifications', id: @company_user.to_param, format: :json

      notifications = JSON.parse(response.body)
      notifications.should include({"message"=>"You have one late task", "level"=>"red", "url"=>"/tasks/mine?end_date=&start_date=&status%5B%5D=Active&task_status%5B%5D=Late&user%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-task"})
    end

    it "should return a notification if the user is part of the event's team that have a late task" do
      event = FactoryGirl.create(:event, company: @company)
      event.users << @company_user
      task = FactoryGirl.create(:late_task, event: event, company_user_id: nil)

      Sunspot.commit

      get 'notifications', id: @company_user.to_param, format: :json

      notifications = JSON.parse(response.body)
      notifications.should include({"message"=>"Your team has one late task", "level"=>"red", "url"=>"/tasks/my_teams?end_date=&not_assigned_to%5B%5D=#{@company_user.id}&start_date=&status%5B%5D=Active&task_status%5B%5D=Late&team_members%5B%5D=#{@company_user.id}", "unread"=>true, "icon"=>"icon-notification-task"})
    end

    it "should return a notification if the user is part of the event's team and a new task is created on that event" do
      event = FactoryGirl.create(:event, company: @company)
      event.users << @company_user
      task = FactoryGirl.create(:task, title: 'The task title', event: event)

      Sunspot.commit

      get 'notifications', id: @company_user.to_param, format: :json

      notifications = JSON.parse(response.body)
      notifications.should include({"message"=>"A new task was created for your event: The task title", "level"=>"grey", "url"=>"/tasks/my_teams?q=task%2C#{task.id}&notifid=#{Notification.last.id}", "unread"=>true, "icon"=>"icon-notification-task"})
    end
  end
end